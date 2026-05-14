<?php

declare(strict_types=1);

namespace App\Repository;

use App\Entity\UserNotification;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;

class UserNotificationRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, UserNotification::class);
    }

    public function findByUser(int $userId, bool $unreadOnly, int $limit): array
    {
        $qb = $this->createQueryBuilder('n')
            ->where('n.user = :userId')
            ->setParameter('userId', $userId);

        if ($unreadOnly) {
            $qb->andWhere('n.isRead = :read')
               ->setParameter('read', false);
        }

        return $qb->orderBy('n.createdAt', 'DESC')
            ->setMaxResults($limit)
            ->getQuery()
            ->getResult();
    }

    public function markAllRead(int $userId): void
    {
        $now = new \DateTime();
        $this->createQueryBuilder('n')
            ->update()
            ->set('n.isRead', ':read')
            ->set('n.readAt', ':now')
            ->where('n.user = :userId')
            ->andWhere('n.isRead = :unread')
            ->setParameter('read', true)
            ->setParameter('unread', false)
            ->setParameter('userId', $userId)
            ->setParameter('now', $now)
            ->getQuery()
            ->execute();
    }

    public function save(UserNotification $notification, bool $flush = true): void
    {
        $this->getEntityManager()->persist($notification);
        if ($flush) {
            $this->getEntityManager()->flush();
        }
    }
}
