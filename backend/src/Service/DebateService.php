<?php

declare(strict_types=1);

namespace App\Service;

use App\Entity\Debate;
use App\Entity\User;
use App\Repository\DebateRepository;
use App\Repository\UserRepository;

class DebateService
{
    private const PAGE_SIZE = 20;

    public function __construct(
        private readonly DebateRepository $debateRepository,
        private readonly UserRepository $userRepository
    ) {
    }

    public function getTodaysDebates(): array
    {
        return $this->debateRepository->findTodaysDebates();
    }

    public function getTrending(): array
    {
        return $this->debateRepository->findTrending(20);
    }

    public function getDebate(int $id): Debate
    {
        $debate = $this->debateRepository->find($id);
        if ($debate === null) {
            throw new \RuntimeException('NOT_FOUND: debate not found');
        }
        return $debate;
    }

    public function search(string $query, int $page): array
    {
        $offset = ($page - 1) * self::PAGE_SIZE;
        return $this->debateRepository->search($query, self::PAGE_SIZE, $offset);
    }

    public function proposeDebate(User $user, array $data): Debate
    {
        if (empty($data['title'])) {
            throw new \InvalidArgumentException('title is required');
        }
        if (empty($data['context'])) {
            throw new \InvalidArgumentException('context is required');
        }

        $debate = new Debate();
        $debate->setTitle($data['title']);
        $debate->setContext($data['context']);
        $debate->setQuestion($data['question'] ?? null);
        $debate->setCardSummary($data['cardSummary'] ?? null);
        $debate->setSourceName($data['sourceName'] ?? null);
        $debate->setSourceUrl($data['sourceUrl'] ?? null);
        $debate->setDayDate(new \DateTime());
        $debate->setCreatedBy($user);
        $debate->setAuthorType('user');

        $this->debateRepository->save($debate);

        return $debate;
    }

    public function getPersonaDebates(string $username, int $page): array
    {
        $persona = $this->userRepository->findByUsername($username);
        if ($persona === null || !$persona->isAiPersona()) {
            throw new \RuntimeException('NOT_FOUND: persona not found');
        }

        $offset = ($page - 1) * self::PAGE_SIZE;
        return $this->debateRepository->findByPersona($persona, self::PAGE_SIZE, $offset);
    }
}
