<?php

declare(strict_types=1);

namespace App\Repository;

use App\Entity\ChatMessage;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;

class ChatMessageRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, ChatMessage::class);
    }

    public function findByConversation(int $conversationId, int $limit, int $offset): array
    {
        return $this->createQueryBuilder('m')
            ->where('m.conversation = :conversationId')
            ->setParameter('conversationId', $conversationId)
            ->orderBy('m.createdAt', 'DESC')
            ->setMaxResults($limit)
            ->setFirstResult($offset)
            ->getQuery()
            ->getResult();
    }

    public function findLastByConversation(int $conversationId): ?ChatMessage
    {
        $result = $this->createQueryBuilder('m')
            ->where('m.conversation = :conversationId')
            ->setParameter('conversationId', $conversationId)
            ->orderBy('m.createdAt', 'DESC')
            ->setMaxResults(1)
            ->getQuery()
            ->getOneOrNullResult();

        return $result instanceof ChatMessage ? $result : null;
    }

    public function countUnread(int $conversationId, int $userId, ?int $lastReadMsgId): int
    {
        $qb = $this->createQueryBuilder('m')
            ->select('COUNT(m.id)')
            ->where('m.conversation = :conversationId')
            ->andWhere('m.sender != :userId')
            ->setParameter('conversationId', $conversationId)
            ->setParameter('userId', $userId);

        if ($lastReadMsgId !== null) {
            $qb->andWhere('m.id > :lastReadMsgId')
               ->setParameter('lastReadMsgId', $lastReadMsgId);
        }

        return (int) $qb->getQuery()->getSingleScalarResult();
    }

    public function save(ChatMessage $message, bool $flush = true): void
    {
        $this->getEntityManager()->persist($message);
        if ($flush) {
            $this->getEntityManager()->flush();
        }
    }
}
