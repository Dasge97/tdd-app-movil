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
        if (empty($data['personaUsername'])) {
            throw new \InvalidArgumentException('personaUsername is required');
        }

        $persona = $this->userRepository->findByUsername($data['personaUsername']);
        if ($persona === null) {
            throw new \InvalidArgumentException('persona not found: ' . $data['personaUsername']);
        }

        $debate = new Debate();
        $debate->setTitle($data['title']);
        $debate->setContext($data['context']);
        $debate->setQuestion($data['question'] ?? null);
        $debate->setCardSummary($data['cardSummary'] ?? null);
        $debate->setSourceName($data['sourceName'] ?? null);
        $debate->setSourceUrl($data['sourceUrl'] ?? null);
        $debate->setDayDate(isset($data['dayDate']) ? new \DateTime($data['dayDate']) : new \DateTime());
        $debate->setCreatedBy($persona);
        $debate->setAuthorType('ai');
        $debate->setWorkerRun($run);
        $debate->setGenerationModel($data['generationModel'] ?? null);

        if (!empty($data['publishedAt'])) {
            $debate->setPublishedAt(new \DateTime($data['publishedAt']));
        }

        $this->debateRepository->save($debate);

        return $debate;
    }
}
