<?php

declare(strict_types=1);

namespace App\Controller\Api;

use App\Entity\ChatConversation;
use App\Entity\ChatMessage;
use App\Entity\User;
use App\Repository\ChatMessageRepository;
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
        private readonly ChatMessageRepository $messageRepository,
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
            array_map(fn(ChatConversation $c) => $this->normalizeConversation($c, $user), $conversations)
        );
    }

    #[Route('/conversations', name: 'api_chat_conversation_create', methods: ['POST'])]
    public function getOrCreateConversation(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->attributes->get('currentUser');
        $data = json_decode($request->getContent(), true) ?? [];
        $otherUserId = (int) ($data['userId'] ?? 0);

        if ($otherUserId === 0 || $otherUserId === $user->getId()) {
            throw new \InvalidArgumentException('userId is required and must differ from current user');
        }

        $other = $this->userRepository->find($otherUserId);
        if ($other === null) {
            throw new \RuntimeException('NOT_FOUND: user not found');
        }

        $conversation = $this->chatService->getOrCreateConversation($user, $other);

        return new JsonResponse($this->normalizeConversation($conversation, $user), 201);
    }

    #[Route('/conversations/{id}', name: 'api_chat_conversation_show', methods: ['GET'], requirements: ['id' => '\d+'])]
    public function getConversation(int $id, Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->attributes->get('currentUser');
        $conversations = $this->chatService->getConversations($user);

        foreach ($conversations as $conv) {
            if ($conv->getId() === $id) {
                return new JsonResponse($this->normalizeConversation($conv, $user));
            }
        }

        throw new \RuntimeException('NOT_FOUND: conversation not found');
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

    private function normalizeConversation(ChatConversation $conversation, User $currentUser): array
    {
        $participants = [];
        $otherUser = null;
        $myParticipant = null;

        foreach ($conversation->getParticipants() as $p) {
            $u = $p->getUser();
            $participants[] = [
                'userId'        => $u->getId(),
                'username'      => $u->getUsername(),
                'avatarUrl'     => $u->getAvatarUrl(),
                'lastReadMsgId' => $p->getLastReadMsgId(),
            ];

            if ($u->getId() === $currentUser->getId()) {
                $myParticipant = $p;
            } else {
                $otherUser = $u;
            }
        }

        $lastReadMsgId = $myParticipant?->getLastReadMsgId();
        $unreadCount = $this->messageRepository->countUnread(
            $conversation->getId(),
            $currentUser->getId(),
            $lastReadMsgId
        );

        $lastMessage = $this->messageRepository->findLastByConversation($conversation->getId());

        return [
            'id'           => $conversation->getId(),
            'dmKey'        => $conversation->getDmKey(),
            'createdAt'    => $conversation->getCreatedAt()->format(\DateTimeInterface::ATOM),
            'updatedAt'    => $conversation->getUpdatedAt()?->format(\DateTimeInterface::ATOM),
            'participants' => $participants,
            'otherUser'    => $otherUser !== null ? [
                'id'        => $otherUser->getId(),
                'username'  => $otherUser->getUsername(),
                'avatarUrl' => $otherUser->getAvatarUrl(),
                'bio'       => $otherUser->getBio(),
            ] : null,
            'lastMessage'  => $lastMessage !== null ? $this->normalizeMessage($lastMessage) : null,
            'unreadCount'  => $unreadCount,
        ];
    }

    private function normalizeMessage(ChatMessage $message): array
    {
        return [
            'id'             => $message->getId(),
            'content'        => $message->getContent(),
            'createdAt'      => $message->getCreatedAt()->format(\DateTimeInterface::ATOM),
            'conversationId' => $message->getConversation()->getId(),
            'senderId'       => $message->getSender()->getId(),
            'sender'         => [
                'id'       => $message->getSender()->getId(),
                'username' => $message->getSender()->getUsername(),
                'avatarUrl' => $message->getSender()->getAvatarUrl(),
            ],
        ];
    }
}
