<?php

declare(strict_types=1);

namespace App\Command;

use App\Service\ChatService;
use App\Service\JwtService;
use App\Repository\UserRepository;
use Ratchet\RFC6455\Handshake\RequestVerifier;
use Ratchet\RFC6455\Handshake\ServerNegotiator;
use Ratchet\RFC6455\Messaging\MessageBuffer;
use Ratchet\RFC6455\Messaging\Frame;
use React\EventLoop\Loop;
use React\Socket\SocketServer;
use Symfony\Component\Console\Attribute\AsCommand;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Input\InputOption;
use Symfony\Component\Console\Output\OutputInterface;
use Symfony\Component\Console\Style\SymfonyStyle;
use Psr\Http\Message\RequestInterface;

#[AsCommand(
    name: 'app:websocket-server',
    description: 'Starts the WebSocket server'
)]
class WebSocketServerCommand extends Command
{
    /** @var array<int, array{conn: mixed, userId: int}> */
    private array $connections = [];
    /** @var array<int, int> userId => resourceId */
    private array $userMap = [];

    public function __construct(
        private readonly JwtService $jwtService,
        private readonly UserRepository $userRepository,
        private readonly ChatService $chatService,
        private readonly int $wsPort
    ) {
        parent::__construct();
    }

    protected function configure(): void
    {
        $this->addOption('port', 'p', InputOption::VALUE_OPTIONAL, 'Port to listen on');
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $io = new SymfonyStyle($input, $output);
        $port = $input->getOption('port') ?? $this->wsPort;

        $io->info("Starting WebSocket server on port {$port}");

        $loop = Loop::get();
        $negotiator = new ServerNegotiator(new RequestVerifier());

        $socket = new SocketServer("0.0.0.0:{$port}", [], $loop);

        $socket->on('connection', function ($conn) use ($negotiator, $io) {
            $resourceId = spl_object_id($conn);
            $io->writeln("New TCP connection [{$resourceId}]");

            $headers = '';
            $handshakeDone = false;
            $msgBuffer = null;
            $userId = null;

            $conn->on('data', function (string $data) use (
                $conn, $negotiator, $io, $resourceId,
                &$headers, &$handshakeDone, &$msgBuffer, &$userId
            ) {
                if (!$handshakeDone) {
                    $headers .= $data;

                    // Check if we have full HTTP request
                    if (!str_contains($headers, "\r\n\r\n")) {
                        return;
                    }

                    // Parse the HTTP request for WebSocket upgrade
                    $request = $this->parseHttpRequest($headers);
                    if ($request === null) {
                        $conn->end("HTTP/1.1 400 Bad Request\r\n\r\n");
                        return;
                    }

                    // Extract token from query string
                    $query = $request['query'] ?? '';
                    parse_str($query, $params);
                    $token = $params['token'] ?? '';

                    // Validate JWT
                    try {
                        $payload = $this->jwtService->decode($token);
                        $userId = (int) ($payload['sub'] ?? 0);
                        $user = $this->userRepository->find($userId);
                        if ($user === null) {
                            $conn->end("HTTP/1.1 401 Unauthorized\r\n\r\n");
                            return;
                        }
                    } catch (\Exception $e) {
                        $conn->end("HTTP/1.1 401 Unauthorized\r\n\r\n");
                        return;
                    }

                    // Do WebSocket handshake
                    $psrRequest = $this->buildPsrRequest($request);
                    $response = $negotiator->handshake($psrRequest);

                    if ($response->getStatusCode() !== 101) {
                        $conn->end("HTTP/1.1 400 Bad Request\r\n\r\n");
                        return;
                    }

                    // Send upgrade response
                    $responseStr = "HTTP/1.1 101 Switching Protocols\r\n";
                    foreach ($response->getHeaders() as $name => $values) {
                        foreach ($values as $value) {
                            $responseStr .= "{$name}: {$value}\r\n";
                        }
                    }
                    $responseStr .= "\r\n";
                    $conn->write($responseStr);

                    $handshakeDone = true;
                    $this->connections[$resourceId] = ['conn' => $conn, 'userId' => $userId];
                    $this->userMap[$userId] = $resourceId;

                    $io->writeln("WebSocket connected: user #{$userId} [{$resourceId}]");

                    // Setup message buffer
                    $msgBuffer = new MessageBuffer(
                        new \Ratchet\RFC6455\Messaging\CloseFrameChecker(),
                        function ($message) use ($conn, $userId, $io, $resourceId) {
                            $this->handleMessage($conn, $userId, $message->getPayload(), $io);
                        },
                        function ($frame) use ($conn) {
                            // Handle control frames (ping/pong/close)
                            if ($frame->getOpCode() === Frame::OP_PING) {
                                $conn->write((new Frame('', true, Frame::OP_PONG))->getContents());
                            }
                            if ($frame->getOpCode() === Frame::OP_CLOSE) {
                                $conn->end($frame->getContents());
                            }
                        },
                        false, // not masked (server side)
                        null
                    );

                    return;
                }

                // Feed data to message buffer
                if ($msgBuffer !== null) {
                    $msgBuffer->onData($data);
                }
            });

            $conn->on('end', function () use ($resourceId, &$userId, $io) {
                $io->writeln("Connection closed [{$resourceId}]");
                unset($this->connections[$resourceId]);
                if ($userId !== null) {
                    unset($this->userMap[$userId]);
                }
            });

            $conn->on('error', function (\Exception $e) use ($resourceId, $io) {
                $io->writeln("Connection error [{$resourceId}]: " . $e->getMessage());
            });
        });

        $io->success("WebSocket server running on ws://0.0.0.0:{$port}");
        $loop->run();

        return Command::SUCCESS;
    }

    private function handleMessage(mixed $conn, int $userId, string $payload, SymfonyStyle $io): void
    {
        $data = json_decode($payload, true);
        if ($data === null) {
            return;
        }

        $type = $data['type'] ?? '';

        if ($type === 'ping') {
            $frame = new Frame(json_encode(['type' => 'pong']), true, Frame::OP_TEXT);
            $conn->write($frame->getContents());
            return;
        }

        if ($type === 'chat') {
            $conversationId = (int) ($data['conversationId'] ?? 0);
            $content = $data['content'] ?? '';

            if ($conversationId === 0 || empty($content)) {
                return;
            }

            try {
                $sender = $this->userRepository->find($userId);
                if ($sender === null) {
                    return;
                }

                $message = $this->chatService->sendMessage($sender, $conversationId, $content);

                // Find other participants and notify them
                $conversation = $message->getConversation();
                foreach ($conversation->getParticipants() as $participant) {
                    $recipientId = $participant->getUser()->getId();
                    if ($recipientId !== $userId && isset($this->userMap[$recipientId])) {
                        $recipientResourceId = $this->userMap[$recipientId];
                        if (isset($this->connections[$recipientResourceId])) {
                            $recipientConn = $this->connections[$recipientResourceId]['conn'];
                            $notification = json_encode([
                                'type'    => 'chat_message',
                                'message' => [
                                    'id'             => $message->getId(),
                                    'content'        => $message->getContent(),
                                    'conversationId' => $conversationId,
                                    'createdAt'      => $message->getCreatedAt()->format(\DateTimeInterface::ATOM),
                                    'sender'         => [
                                        'id'       => $sender->getId(),
                                        'username' => $sender->getUsername(),
                                    ],
                                ],
                            ]);
                            $frame = new Frame($notification, true, Frame::OP_TEXT);
                            $recipientConn->write($frame->getContents());
                        }
                    }
                }

                // Confirm to sender
                $confirm = json_encode([
                    'type'      => 'message_sent',
                    'messageId' => $message->getId(),
                ]);
                $frame = new Frame($confirm, true, Frame::OP_TEXT);
                $conn->write($frame->getContents());

            } catch (\Exception $e) {
                $io->writeln("Chat error: " . $e->getMessage());
            }
        }
    }

    private function parseHttpRequest(string $raw): ?array
    {
        $lines = explode("\r\n", $raw);
        if (empty($lines)) {
            return null;
        }

        $firstLine = array_shift($lines);
        $parts = explode(' ', $firstLine);
        if (count($parts) < 2) {
            return null;
        }

        $urlParts = parse_url($parts[1]);
        $headers = [];
        foreach ($lines as $line) {
            if (str_contains($line, ':')) {
                [$name, $value] = explode(':', $line, 2);
                $headers[strtolower(trim($name))] = trim($value);
            }
        }

        return [
            'method'  => $parts[0],
            'path'    => $urlParts['path'] ?? '/',
            'query'   => $urlParts['query'] ?? '',
            'headers' => $headers,
        ];
    }

    private function buildPsrRequest(array $request): RequestInterface
    {
        $uri = 'http://localhost' . $request['path'];
        if (!empty($request['query'])) {
            $uri .= '?' . $request['query'];
        }

        $psrRequest = new \GuzzleHttp\Psr7\Request(
            $request['method'],
            $uri,
            $request['headers']
        );

        return $psrRequest;
    }
}
