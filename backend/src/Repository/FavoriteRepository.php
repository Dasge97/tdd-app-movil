<?php

declare(strict_types=1);

namespace App\Repository;

use App\Entity\Favorite;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\DBAL\Connection;
use Doctrine\Persistence\ManagerRegistry;

class FavoriteRepository extends ServiceEntityRepository
{
    public function __construct(
        ManagerRegistry $registry,
        private readonly Connection $connection
    ) {
        parent::__construct($registry, Favorite::class);
    }

    public function findByUserAndDebate(int $userId, int $debateId): ?Favorite
    {
        return $this->findOneBy(['user' => $userId, 'debate' => $debateId]);
    }

    public function findByUser(int $userId, int $limit, int $offset): array
    {
        return $this->createQueryBuilder('f')
            ->where('f.user = :userId')
            ->setParameter('userId', $userId)
            ->orderBy('f.createdAt', 'DESC')
            ->setMaxResults($limit)
            ->setFirstResult($offset)
            ->getQuery()
            ->getResult();
    }

    public function upsert(int $userId, int $debateId): void
    {
        $now = (new \DateTime())->format('Y-m-d H:i:s');

        $this->connection->executeStatement(
            'INSERT IGNORE INTO favorites (user_id, debate_id, created_at)
             VALUES (:userId, :debateId, :now)',
            [
                'userId'   => $userId,
                'debateId' => $debateId,
                'now'      => $now,
            ]
        );
    }

    public function delete(int $userId, int $debateId): void
    {
        $this->connection->executeStatement(
            'DELETE FROM favorites WHERE user_id = :userId AND debate_id = :debateId',
            [
                'userId'   => $userId,
                'debateId' => $debateId,
            ]
        );
    }
}
