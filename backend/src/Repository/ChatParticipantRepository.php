<?php

declare(strict_types=1);

namespace App\Repository;

use App\Entity\ChatParticipant;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;

class ChatParticipantRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, ChatParticipant::class);
    }

    public function save(ChatParticipant $participant, bool $flush = true): void
    {
        $this->getEntityManager()->persist($participant);
        if ($flush) {
            $this->getEntityManager()->flush();
        }
    }
}
