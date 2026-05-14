<?php

declare(strict_types=1);

namespace App\Repository;

use App\Entity\Vote;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\DBAL\Connection;
use Doctrine\Persistence\ManagerRegistry;

class VoteRepository extends ServiceEntityRepository
{
    public function __construct(
        ManagerRegistry $registry,
        private readonly Connection $connection
    ) {
        parent::__construct($registry, Vote::class);
    }

    public function findByUserAndComment(int $userId, int $commentId): ?Vote
    {
        return $this->findOneBy(['user' => $userId, 'comment' => $commentId]);
    }

    public function upsert(int $userId, int $commentId, int $value): void
    {
        $now = (new \DateTime())->format('Y-m-d H:i:s');

        $this->connection->executeStatement(
            'INSERT INTO votes (user_id, comment_id, value, created_at)
             VALUES (:userId, :commentId, :value, :now)
             ON DUPLICATE KEY UPDATE value = :value',
            [
                'userId'    => $userId,
                'commentId' => $commentId,
                'value'     => $value,
                'now'       => $now,
            ]
        );
    }
}
