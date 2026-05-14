<?php

declare(strict_types=1);

namespace App\Repository;

use App\Entity\Friend;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;

class FriendRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, Friend::class);
    }

    public function findRelation(int $userId1, int $userId2): ?Friend
    {
        return $this->createQueryBuilder('f')
            ->where(
                '(f.requester = :u1 AND f.addressee = :u2) OR (f.requester = :u2 AND f.addressee = :u1)'
            )
            ->setParameter('u1', $userId1)
            ->setParameter('u2', $userId2)
            ->getQuery()
            ->getOneOrNullResult();
    }

    public function findFriends(int $userId): array
    {
        return $this->createQueryBuilder('f')
            ->where('(f.requester = :userId OR f.addressee = :userId) AND f.status = :status')
            ->setParameter('userId', $userId)
            ->setParameter('status', 'accepted')
            ->orderBy('f.createdAt', 'DESC')
            ->getQuery()
            ->getResult();
    }

    public function findPending(int $userId): array
    {
        return $this->createQueryBuilder('f')
            ->where('f.addressee = :userId AND f.status = :status')
            ->setParameter('userId', $userId)
            ->setParameter('status', 'pending')
            ->orderBy('f.createdAt', 'DESC')
            ->getQuery()
            ->getResult();
    }

    public function save(Friend $friend, bool $flush = true): void
    {
        $this->getEntityManager()->persist($friend);
        if ($flush) {
            $this->getEntityManager()->flush();
        }
    }
}
