<?php

declare(strict_types=1);

namespace App\Repository;

use App\Entity\User;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;

class UserRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, User::class);
    }

    public function findByUsername(string $username): ?User
    {
        return $this->findOneBy(['username' => $username]);
    }

    public function findByEmail(string $email): ?User
    {
        return $this->findOneBy(['email' => $email]);
    }

    public function findAiPersonas(): array
    {
        return $this->createQueryBuilder('u')
            ->where('u.isAiPersona = :ai')
            ->andWhere('u.status = :status')
            ->setParameter('ai', true)
            ->setParameter('status', 'active')
            ->orderBy('u.username', 'ASC')
            ->getQuery()
            ->getResult();
    }

    public function findShadowBannedForReview(): array
    {
        return $this->createQueryBuilder('u')
            ->where('u.isShadowBanned = :banned')
            ->setParameter('banned', true)
            ->getQuery()
            ->getResult();
    }

    /** Top usuarios reales por reliabilityScore para el ranking de Protagonistas. */
    public function findProtagonistaRanking(int $limit = 20): array
    {
        return $this->createQueryBuilder('u')
            ->where('u.isAiPersona = :ai')
            ->andWhere('u.isShadowBanned = :banned')
            ->andWhere('u.status = :status')
            ->setParameter('ai', false)
            ->setParameter('banned', false)
            ->setParameter('status', 'active')
            ->orderBy('u.reliabilityScore', 'DESC')
            ->setMaxResults($limit)
            ->getQuery()
            ->getResult();
    }

    public function save(User $user, bool $flush = true): void
    {
        $this->getEntityManager()->persist($user);
        if ($flush) {
            $this->getEntityManager()->flush();
        }
    }
}
