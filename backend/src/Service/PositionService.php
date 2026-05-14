<?php

declare(strict_types=1);

namespace App\Service;

use App\Entity\Position;
use App\Entity\User;
use App\Repository\DebateRepository;
use App\Repository\PositionRepository;

class PositionService
{
    private const VALID_POSITIONS = ['support', 'oppose', 'neutral'];

    public function __construct(
        private readonly PositionRepository $positionRepository,
        private readonly DebateRepository $debateRepository
    ) {
    }

    public function setPosition(User $user, int $debateId, string $position): Position
    {
        if (!in_array($position, self::VALID_POSITIONS, true)) {
            throw new \InvalidArgumentException('position must be support, oppose, or neutral');
        }

        $debate = $this->debateRepository->find($debateId);
        if ($debate === null) {
            throw new \RuntimeException('NOT_FOUND: debate not found');
        }

        $this->positionRepository->upsert($user->getId(), $debateId, $position);

        $pos = $this->positionRepository->findByUserAndDebate($user->getId(), $debateId);
        if ($pos === null) {
            // Fallback: create manually if upsert result not immediately visible
            $pos = new Position();
            $pos->setUser($user);
            $pos->setDebate($debate);
            $pos->setPosition($position);
            $this->positionRepository->save($pos);
        }

        return $pos;
    }

    public function getPositions(int $debateId): array
    {
        return $this->positionRepository->countByDebate($debateId);
    }
}
