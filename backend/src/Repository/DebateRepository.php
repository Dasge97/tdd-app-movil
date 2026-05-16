<?php

declare(strict_types=1);

namespace App\Repository;

use App\Entity\Debate;
use App\Entity\User;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;

class DebateRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, Debate::class);
    }

    public function findTodaysDebates(): array
    {
        $today = new \DateTime();
        $today->setTime(0, 0, 0);

        return $this->createQueryBuilder('d')
            ->where('d.dayDate = :today')
            ->setParameter('today', $today->format('Y-m-d'))
            ->orderBy('d.createdAt', 'DESC')
            ->getQuery()
            ->getResult();
    }

    public function findByDayDate(\DateTimeInterface $date): array
    {
        return $this->createQueryBuilder('d')
            ->where('d.dayDate = :date')
            ->setParameter('date', $date->format('Y-m-d'))
            ->orderBy('d.createdAt', 'DESC')
            ->getQuery()
            ->getResult();
    }

    public function findTrending(int $limit = 20): array
    {
        $since = new \DateTime('-48 hours');

        return $this->createQueryBuilder('d')
            ->leftJoin('d.comments', 'c')
            ->where('c.createdAt >= :since OR c.createdAt IS NULL')
            ->setParameter('since', $since)
            ->groupBy('d.id')
            ->orderBy('COUNT(c.id)', 'DESC')
            ->setMaxResults($limit)
            ->getQuery()
            ->getResult();
    }

    public function findByPersona(User $persona, int $limit, int $offset): array
    {
        return $this->createQueryBuilder('d')
            ->where('d.createdBy = :persona')
            ->setParameter('persona', $persona)
            ->orderBy('d.createdAt', 'DESC')
            ->setMaxResults($limit)
            ->setFirstResult($offset)
            ->getQuery()
            ->getResult();
    }

    public function findRecentTitles(int $days): array
    {
        $since = new \DateTime("-{$days} days");

        return $this->createQueryBuilder('d')
            ->select('d.title')
            ->where('d.createdAt >= :since')
            ->setParameter('since', $since)
            ->getQuery()
            ->getSingleColumnResult();
    }

    public function findRecentForWorker(int $days): array
    {
        $since = new \DateTime("-{$days} days");

        return $this->createQueryBuilder('d')
            ->select('d.title', 'd.dayDate')
            ->where('d.dayDate >= :since')
            ->setParameter('since', $since->format('Y-m-d'))
            ->orderBy('d.dayDate', 'DESC')
            ->getQuery()
            ->getResult();
    }

    public function findLastDateByPersona(User $persona): ?\DateTimeInterface
    {
        $row = $this->createQueryBuilder('d')
            ->select('d.dayDate')
            ->where('d.createdBy = :persona')
            ->setParameter('persona', $persona)
            ->orderBy('d.dayDate', 'DESC')
            ->setMaxResults(1)
            ->getQuery()
            ->getOneOrNullResult();

        return $row ? $row['dayDate'] : null;
    }

    public function search(string $query, int $limit, int $offset): array
    {
        return $this->createQueryBuilder('d')
            ->where('d.title LIKE :q OR d.context LIKE :q OR d.cardSummary LIKE :q')
            ->setParameter('q', '%' . $query . '%')
            ->orderBy('d.createdAt', 'DESC')
            ->setMaxResults($limit)
            ->setFirstResult($offset)
            ->getQuery()
            ->getResult();
    }

    /** Debates para el ticker: todos, ordenados por nº de comentarios. */
    public function findForTicker(int $limit = 20): array
    {
        return $this->createQueryBuilder('d')
            ->leftJoin('d.comments', 'c')
            ->groupBy('d.id')
            ->orderBy('COUNT(c.id)', 'DESC')
            ->setMaxResults($limit)
            ->getQuery()
            ->getResult();
    }

    /** Top debates de hoy por nº de comentarios. */
    public function findTopToday(int $limit = 10): array
    {
        $today = (new \DateTime())->setTime(0, 0, 0);

        return $this->createQueryBuilder('d')
            ->leftJoin('d.comments', 'c')
            ->where('d.dayDate = :today')
            ->setParameter('today', $today->format('Y-m-d'))
            ->groupBy('d.id')
            ->orderBy('COUNT(c.id)', 'DESC')
            ->setMaxResults($limit)
            ->getQuery()
            ->getResult();
    }

    /** Top debates de los últimos 7 días por nº de comentarios. */
    public function findTopWeek(int $limit = 10): array
    {
        $since = (new \DateTime())->modify('-7 days')->setTime(0, 0, 0);

        return $this->createQueryBuilder('d')
            ->leftJoin('d.comments', 'c')
            ->where('d.dayDate >= :since')
            ->setParameter('since', $since->format('Y-m-d'))
            ->groupBy('d.id')
            ->orderBy('COUNT(c.id)', 'DESC')
            ->setMaxResults($limit)
            ->getQuery()
            ->getResult();
    }

    /** Debates recientes, con filtro opcional por persona (username). */
    public function findRecent(int $limit = 20, int $offset = 0, ?string $personaUsername = null): array
    {
        $qb = $this->createQueryBuilder('d')
            ->leftJoin('d.createdBy', 'u')
            ->orderBy('d.createdAt', 'DESC')
            ->setMaxResults($limit)
            ->setFirstResult($offset);

        if ($personaUsername !== null) {
            $qb->where('u.username = :persona')
               ->setParameter('persona', $personaUsername);
        }

        return $qb->getQuery()->getResult();
    }

    public function save(Debate $debate, bool $flush = true): void
    {
        $this->getEntityManager()->persist($debate);
        if ($flush) {
            $this->getEntityManager()->flush();
        }
    }
}
