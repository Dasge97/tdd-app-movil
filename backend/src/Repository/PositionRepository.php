<?php

declare(strict_types=1);

namespace App\Repository;

use App\Entity\Position;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;

class PositionRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
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
        $em = $this->getEntityManager();
        $existing = $this->findByUserAndDebate($userId, $debateId);

        if ($existing) {
            $existing->setPosition($position);
            $existing->setUpdatedAt(new \DateTime());
            $em->flush();
        } else {
            $em->getConnection()->executeStatement(
                'INSERT INTO positions (user_id, debate_id, position, created_at) VALUES (?, ?, ?, NOW())',
                [$userId, $debateId, $position]
            );
        }
    }

    public function save(Position $position, bool $flush = true): void
    {
        $this->getEntityManager()->persist($position);
        if ($flush) {
            $this->getEntityManager()->flush();
        }
    }
}
