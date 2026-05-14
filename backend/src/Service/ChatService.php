<?php

declare(strict_types=1);

namespace App\Service;

use App\Entity\ChatConversation;
use App\Entity\ChatMessage;
use App\Entity\ChatParticipant;
use App\Entity\User;
use App\Repository\ChatConversationRepository;
use App\Repository\ChatMessageRepository;
use App\Repository\UserRepository;

class ChatService
{
    private const PAGE_SIZE = 30;

    public function __construct(
        private readonly ChatConversationRepository $conversationRepository,
        private readonly ChatMessageRepository $messageRepository,
        private readonly UserRepository $userRepository
    ) {
    }

    public function getConversations(User $user): array
    {
        return $this->conversationRepository->findByUser($user->getId());
    }

    public function getOrCreateConversation(User $user1, User $user2): ChatConversation
    {
        $ids = [$user1->getId(), $user2->getId()];
        sort($ids);
        $dmKey = implode(':', $ids);

        $conversation = $this->conversationRepository->findByDmKey($dmKey);

        if ($conversation === null) {
            $conversation = new ChatConversation();
            $conversation->setDmKey($dmKey);

            $p1 = new ChatParticipant();
            $p1->setConversation($conversation);
            $p1->setUser($user1);

            $p2 = new ChatParticipant();
            $p2->setConversation($conversation);
            $p2->setUser($user2);

            $em = $this->conversationRepository->getEntityManager();
            $em->persist($conversation);
            $em->persist($p1);
            $em->persist($p2);
            $em->flush();
        }

        return $conversation;
    }

    public function getMessages(User $user, int $conversationId, int $page): array
    {
        $conversation = $this->conversationRepository->find($conversationId);
        if ($conversation === null) {
            throw new \RuntimeException('NOT_FOUND: conversation not found');
        }

        // Check user is participant
        $isParticipant = false;
        foreach ($conversation->getParticipants() as $participant) {
            if ($participant->getUser()->getId() === $user->getId()) {
                $isParticipant = true;
                break;
            }
        }

        if (!$isParticipant) {
            throw new \RuntimeException('FORBIDDEN: not a participant');
        }

        $offset = ($page - 1) * self::PAGE_SIZE;
        return $this->messageRepository->findByConversation($conversationId, self::PAGE_SIZE, $offset);
    }

    public function sendMessage(User $sender, int $conversationId, string $content): ChatMessage
    {
        if (empty(trim($content))) {
            throw new \InvalidArgumentException('content cannot be empty');
        }

        $conversation = $this->conversationRepository->find($conversationId);
        if ($conversation === null) {
            throw new \RuntimeException('NOT_FOUND: conversation not found');
        }

        $isParticipant = false;
        foreach ($conversation->getParticipants() as $participant) {
            if ($participant->getUser()->getId() === $sender->getId()) {
                $isParticipant = true;
                break;
            }
        }

        if (!$isParticipant) {
            throw new \RuntimeException('FORBIDDEN: not a participant');
        }

        $message = new ChatMessage();
        $message->setConversation($conversation);
        $message->setSender($sender);
        $message->setContent(trim($content));

        $conversation->setUpdatedAt(new \DateTime());

        $this->messageRepository->save($message);

        return $message;
    }
}
