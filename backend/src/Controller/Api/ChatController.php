<?php

declare(strict_types=1);

namespace App\Controller\Api;

use App\Entity\ChatConversation;
use App\Entity\ChatMessage;
use App\Entity\User;
use App\Repository\UserRepository;
use App\Service\ChatService;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\Routing\Attribute\Route;

#[Route('/api/v1/chat')]
class ChatController extends AbstractController
{
    public function __construct(
        private readonly ChatService $chatService,
        private readonly UserRepository $userRepository
    ) {
    }

    #[Route('/conversations', name: 'api_chat_conversations', methods: ['GET'])]
    public function getConversations(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->attributes->get('currentUser');
        $conversations = $this->chatService->getConversations($user);

        return new JsonResponse(
            array_map(fn(ChatConversation $c) => $this->normalizeConversation($c), $conversations)
        );
    }

    #[Route('/conversations/{id}/messages', name: 'api_chat_messages_list', methods: ['GET'], requirements: ['id' => '\d+'])]
    public function getMessages(int $id, Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->attributes->get('currentUser');
        $page = max(1, (int) $request->query->get('page', '1'));

        $messages = $this->chatService->getMessages($user, $id, $page);

        return new JsonResponse(
            array_map(fn(ChatMessage $m) => $this->normalizeMessage($m), $messages)
        );
    }

    #[Route('/conversations/{id}/messages', name: 'api_chat_messages_send', methods: ['POST'], requirements: ['id' => '\d+'])]
    public function sendMessage(int $id, Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->attributes->get('currentUser');
        $data = json_decode($request->getContent(), true) ?? [];
        $content = $data['content'] ?? '';

        $message = $this->chatService->sendMessage($user, $id, $content);

        return new JsonResponse($this->normalizeMessage($message), 201);
    }

    private function normalizeConversation(ChatConversation $conversation): array
    {
        $participants = [];
        foreach ($conversation->getParticipants() as $p) {
            $participants[] = [
                'userId'       => $p->getUser()->getId(),
                'username'     => $p->getUser()->getUsername(),
                'avatarUrl'    => $p->getUser()->getAvatarUrl(),
                'lastReadMsgId' => $p->getLastReadMsgId(),
            ];
        }

        return [
            'id'           => $conversation->getId(),
            'dmKey'        => $conversation->getDmKey(),
            'createdAt'    => $conversation->getCreatedAt()->format(\DateTimeInterface::ATOM),
            'updatedAt'    => $conversation->getUpdatedAt()?->format(\DateTimeInterface::ATOM),
            'participants' => $participants,
        ];
    }

    private function normalizeMessage(ChatMessage $message): array
    {
        return [
            'id'             => $message->getId(),
            'content'        => $message->getContent(),
            'createdAt'      => $message->getCreatedAt()->format(\DateTimeInterface::ATOM),
            'conversationId' => $message->getConversation()->getId(),
            'sender'         => [
                'id'       => $message->getSender()->getId(),
                'username' => $message->getSender()->getUsername(),
                'avatarUrl' => $message->getSender()->getAvatarUrl(),
            ],
        ];
    }
}
