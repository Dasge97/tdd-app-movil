<?php

declare(strict_types=1);

namespace App\Repository;

use App\Entity\Position;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\DBAL\Connection;
use Doctrine\Persistence\ManagerRegistry;

class PositionRepository extends ServiceEntityRepository
{
    public function __construct(
        ManagerRegistry $registry,
        private readonly Connection $connection
    ) {
        parent::__construct($registry, Position::class);
    }

    public function findByUserAndDebate(int $userId, int $debateId): ?Position
    {
        return $this->findOneBy(['user' => $userId, 'debate' => $debateId]);
    }

    public function countByDebate(int $debateId): array
    {
        $rows = $this->createQueryBuilder('p')
            ->select('p.position, COUNT(p.id) as cnt')
            ->where('p.debate = :debateId')
            ->setParameter('debateId', $debateId)
            ->groupBy('p.position')
            ->getQuery()
            ->getArrayResult();

        $result = ['support' => 0, 'oppose' => 0, 'neutral' => 0];
        foreach ($rows as $row) {
            $result[$row['position']] = (int) $row['cnt'];
        }

        return $result;
    }

    public function upsert(int $userId, int $debateId, string $position): void
    {
        $now = (new \DateTime())->format('Y-m-d H:i:s');

        $this->connection->executeStatement(
            'INSERT INTO positions (user_id, debate_id, position, created_at, updated_at)
             VALUES (:userId, :debateId, :position, :now, :now)
             ON DUPLICATE KEY UPDATE position = :position, updated_at = :now',
            [
                'userId'   => $userId,
                'debateId' => $debateId,
                'position' => $position,
                'now'      => $now,
            ]
        );
    }

    public function save(Position $position, bool $flush = true): void
    {
        $this->getEntityManager()->persist($position);
        if ($flush) {
            $this->getEntityManager()->flush();
        }
    }
}
