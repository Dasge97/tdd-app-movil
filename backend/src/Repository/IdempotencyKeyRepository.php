<?php

declare(strict_types=1);

namespace App\Repository;

use App\Entity\IdempotencyKey;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;

class IdempotencyKeyRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, IdempotencyKey::class);
    }

    public function findByHash(string $hash): ?IdempotencyKey
    {
        return $this->findOneBy(['keyHash' => $hash]);
    }

    public function save(string $hash, int $status, array $body, \DateTimeInterface $expiresAt): void
    {
        $key = new IdempotencyKey();
        $key->setKeyHash($hash);
        $key->setResponseStatus($status);
        $key->setResponseBody($body);
        $key->setExpiresAt($expiresAt);

        $this->getEntityManager()->persist($key);
        $this->getEntityManager()->flush();
    }

    public function cleanExpired(): void
    {
        $now = new \DateTime();
        $this->createQueryBuilder('k')
            ->delete()
            ->where('k.expiresAt < :now')
            ->setParameter('now', $now)
            ->getQuery()
            ->execute();
    }
}
