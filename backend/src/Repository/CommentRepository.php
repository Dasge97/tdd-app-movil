<?php

declare(strict_types=1);

namespace App\Repository;

use App\Entity\Comment;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;

class CommentRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, Comment::class);
    }

    public function findAllByDebate(int $debateId, bool $excludeShadowBanned): array
    {
        $qb = $this->createQueryBuilder('c')
            ->innerJoin('c.user', 'u')
            ->where('c.debate = :debateId')
            ->setParameter('debateId', $debateId);

        if ($excludeShadowBanned) {
            $qb->andWhere('u.isShadowBanned = :banned')
               ->setParameter('banned', false);
        }

        return $qb->orderBy('c.score', 'DESC')
            ->addOrderBy('c.createdAt', 'ASC')
            ->getQuery()
            ->getResult();
    }

    public function countByDebate(int $debateId): int
    {
        return (int) $this->createQueryBuilder('c')
            ->select('COUNT(c.id)')
            ->where('c.debate = :debateId')
            ->setParameter('debateId', $debateId)
            ->getQuery()
            ->getSingleScalarResult();
    }

    public function findByDebate(int $debateId, ?int $parentId, bool $excludeShadowBanned): array
    {
        $qb = $this->createQueryBuilder('c')
            ->innerJoin('c.user', 'u')
            ->where('c.debate = :debateId')
            ->setParameter('debateId', $debateId);

        if ($parentId === null) {
            $qb->andWhere('c.parent IS NULL');
        } else {
            $qb->andWhere('c.parent = :parentId')
               ->setParameter('parentId', $parentId);
        }

        if ($excludeShadowBanned) {
            $qb->andWhere('u.isShadowBanned = :banned')
               ->setParameter('banned', false);
        }

        return $qb->orderBy('c.score', 'DESC')
            ->addOrderBy('c.createdAt', 'ASC')
            ->getQuery()
            ->getResult();
    }

    public function countByUserInLast30Days(int $userId): int
    {
        $since = new \DateTime('-30 days');

        return (int) $this->createQueryBuilder('c')
            ->select('COUNT(c.id)')
            ->where('c.user = :userId')
            ->andWhere('c.createdAt >= :since')
            ->setParameter('userId', $userId)
            ->setParameter('since', $since)
            ->getQuery()
            ->getSingleScalarResult();
    }

    public function countNegativeByUserInLast30Days(int $userId): int
    {
        $since = new \DateTime('-30 days');

        return (int) $this->createQueryBuilder('c')
            ->select('COUNT(c.id)')
            ->where('c.user = :userId')
            ->andWhere('c.createdAt >= :since')
            ->andWhere('c.score < 0')
            ->setParameter('userId', $userId)
            ->setParameter('since', $since)
            ->getQuery()
            ->getSingleScalarResult();
    }

    public function findRecentByUser(int $userId, int $days): array
    {
        $since = new \DateTime("-{$days} days");

        return $this->createQueryBuilder('c')
            ->where('c.user = :userId')
            ->andWhere('c.createdAt >= :since')
            ->setParameter('userId', $userId)
            ->setParameter('since', $since)
            ->orderBy('c.createdAt', 'DESC')
            ->getQuery()
            ->getResult();
    }

    public function save(Comment $comment, bool $flush = true): void
    {
        $this->getEntityManager()->persist($comment);
        if ($flush) {
            $this->getEntityManager()->flush();
        }
    }
}
