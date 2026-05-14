<?php

declare(strict_types=1);

namespace App\Repository;

use App\Entity\RevokedToken;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;

class RevokedTokenRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, RevokedToken::class);
    }

    public function isRevoked(string $jti): bool
    {
        $token = $this->findOneBy(['tokenJti' => $jti]);
        return $token !== null;
    }

    public function cleanExpired(): void
    {
        $now = new \DateTime();
        $this->createQueryBuilder('t')
            ->delete()
            ->where('t.expiresAt < :now')
            ->setParameter('now', $now)
            ->getQuery()
            ->execute();
    }

    public function save(RevokedToken $token, bool $flush = true): void
    {
        $this->getEntityManager()->persist($token);
        if ($flush) {
            $this->getEntityManager()->flush();
        }
    }
}
