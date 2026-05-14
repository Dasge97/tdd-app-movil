<?php

declare(strict_types=1);

namespace App\Repository;

use App\Entity\WorkerConfig;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;

class WorkerConfigRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, WorkerConfig::class);
    }

    public function getConfig(): WorkerConfig
    {
        $config = $this->find(1);

        if ($config === null) {
            $config = new WorkerConfig();
            $config->setId(1);
            $this->getEntityManager()->persist($config);
            $this->getEntityManager()->flush();
        }

        return $config;
    }

    public function save(WorkerConfig $config, bool $flush = true): void
    {
        $this->getEntityManager()->persist($config);
        if ($flush) {
            $this->getEntityManager()->flush();
        }
    }
}
