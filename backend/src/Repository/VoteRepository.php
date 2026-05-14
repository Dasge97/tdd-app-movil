<?php

declare(strict_types=1);

namespace App\Repository;

use App\Entity\Vote;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;

class VoteRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, Vote::class);
    }

    public function findByUserAndComment(int $userId, int $commentId): ?Vote
    {
        return $this->findOneBy(['user' => $userId, 'comment' => $commentId]);
    }

    public function upsert(int $userId, int $commentId, int $value): void
    {
        $em = $this->getEntityManager();
        $existing = $this->findByUserAndComment($userId, $commentId);

        if ($existing) {
            $existing->setValue($value);
            $em->flush();
        } else {
            $em->getConnection()->executeStatement(
                'INSERT INTO votes (user_id, comment_id, value, created_at) VALUES (?, ?, ?, NOW())',
                [$userId, $commentId, $value]
            );
        }
    }
}
