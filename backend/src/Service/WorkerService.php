<?php

declare(strict_types=1);

namespace App\Service;

use App\Entity\Debate;
use App\Entity\WorkerRun;
use App\Repository\DebateRepository;
use App\Repository\UserRepository;
use App\Repository\WorkerRunRepository;

class WorkerService
{
    public function __construct(
        private readonly DebateRepository $debateRepository,
        private readonly WorkerRunRepository $workerRunRepository,
        private readonly UserRepository $userRepository
    ) {
    }

    public function publishDebates(array $debates, string $runId): array
    {
        $run = $this->workerRunRepository->find($runId);
        if ($run === null) {
            $run = new WorkerRun();
            $run->setId($runId);
            $run->setStatus('running');
            $this->workerRunRepository->save($run);
        }

        $created = [];
        $errors = [];

        foreach ($debates as $data) {
            try {
                $debate = $this->createDebateFromData($data, $run);
                $created[] = $debate;
            } catch (\Exception $e) {
                $errors[] = ['error' => $e->getMessage(), 'data' => $data];
            }
        }

        $run->setDebatesGenerated(count($created));
        $run->setStatus(empty($errors) ? 'ok' : 'error');
        $run->setFinishedAt(new \DateTime());

        if (!empty($errors)) {
            $run->setErrorMessage(json_encode($errors));
        }

        $this->workerRunRepository->save($run);

        return [
            'created' => count($created),
            'errors'  => $errors,
            'runId'   => $runId,
        ];
    }

    private function createDebateFromData(array $data, WorkerRun $run): Debate
    {
        if (empty($data['title'])) {
            throw new \InvalidArgumentException('title is required');
        }
        if (empty($data['context'])) {
            throw new \InvalidArgumentException('context is required');
        }

        // Accept persona_id (int) or personaUsername (string)
        $personaId = $data['persona_id'] ?? null;
        $personaUsername = $data['personaUsername'] ?? null;

        if ($personaId !== null) {
            $persona = $this->userRepository->find((int) $personaId);
            if ($persona === null) {
                throw new \InvalidArgumentException('persona not found with id: ' . $personaId);
            }
        } elseif ($personaUsername !== null) {
            $persona = $this->userRepository->findByUsername($personaUsername);
            if ($persona === null) {
                throw new \InvalidArgumentException('persona not found: ' . $personaUsername);
            }
        } else {
            throw new \InvalidArgumentException('persona_id or personaUsername is required');
        }

        // Accept both snake_case (from worker AI output) and camelCase
        $cardSummary    = $data['card_summary']    ?? $data['cardSummary']    ?? null;
        $sourceName     = $data['source_name']     ?? $data['sourceName']     ?? null;
        $sourceUrl      = $data['source_url']      ?? $data['sourceUrl']      ?? null;
        $publishedAt    = $data['published_at']    ?? $data['publishedAt']    ?? null;
        $generationModel = $data['generation_model'] ?? $data['generationModel'] ?? null;
        $dayDate        = $data['day_date']        ?? $data['dayDate']        ?? null;

        $debate = new Debate();
        $debate->setTitle($data['title']);
        $debate->setContext($data['context']);
        $debate->setQuestion($data['question'] ?? null);
        $debate->setCardSummary($cardSummary);
        $debate->setSourceName($sourceName);
        $debate->setSourceUrl($sourceUrl);
        $debate->setDayDate($dayDate !== null ? new \DateTime($dayDate) : new \DateTime());
        $debate->setCreatedBy($persona);
        $debate->setAuthorType('ai');
        $debate->setWorkerRun($run);
        $debate->setGenerationModel($generationModel);

        if (!empty($publishedAt)) {
            $debate->setPublishedAt(new \DateTime($publishedAt));
        }

        $this->debateRepository->save($debate);

        return $debate;
    }
}
