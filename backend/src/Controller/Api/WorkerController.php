<?php

declare(strict_types=1);

namespace App\Controller\Api;

use App\Repository\DebateRepository;
use App\Repository\UserRepository;
use App\Service\AdminService;
use App\Service\WorkerService;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\Routing\Attribute\Route;

#[Route('/api/v1/worker')]
class WorkerController extends AbstractController
{
    public function __construct(
        private readonly WorkerService $workerService,
        private readonly AdminService $adminService,
        private readonly UserRepository $userRepository,
        private readonly DebateRepository $debateRepository,
        private readonly string $workerApiKey
    ) {
    }

    private function requireWorkerKey(Request $request): void
    {
        $apiKey = $request->headers->get('X-Worker-Key', '');
        if (empty($this->workerApiKey) || $apiKey !== $this->workerApiKey) {
            throw new \RuntimeException('UNAUTHORIZED: invalid worker API key');
        }
    }

    #[Route('/config', name: 'api_worker_config', methods: ['GET'])]
    public function getConfig(Request $request): JsonResponse
    {
        $this->requireWorkerKey($request);
        $config = $this->adminService->getWorkerConfig();

        return new JsonResponse([
            'enabled'             => $config->isEnabled(),
            'schedule'            => $config->getSchedule(),
            'trigger_pending'     => $config->isTriggerPending(),
            'dedup_days'          => $config->getDedupDays(),
            'rotation_limit_days' => $config->getRotationLimitDays(),
            'target_debates'      => $config->getTargetDebates(),
        ]);
    }

    #[Route('/ack', name: 'api_worker_ack', methods: ['POST'])]
    public function acknowledge(Request $request): JsonResponse
    {
        $this->requireWorkerKey($request);
        $this->adminService->resetTriggerPending();
        return new JsonResponse(['success' => true]);
    }

    #[Route('/trigger', name: 'api_worker_trigger_self', methods: ['POST'])]
    public function trigger(Request $request): JsonResponse
    {
        $this->requireWorkerKey($request);
        $this->adminService->triggerWorker();
        return new JsonResponse(['success' => true]);
    }

    #[Route('/personas', name: 'api_worker_personas', methods: ['GET'])]
    public function getPersonas(Request $request): JsonResponse
    {
        $this->requireWorkerKey($request);

        $personas = $this->userRepository->findAiPersonas();
        $now = new \DateTime();
        $result = [];

        foreach ($personas as $persona) {
            $lastDate = $this->debateRepository->findLastDateByPersona($persona);
            $daysSince = $lastDate !== null ? (int) $lastDate->diff($now)->days : null;

            $result[] = [
                'id'         => $persona->getId(),
                'username'   => $persona->getUsername(),
                'specialty'  => $persona->getPersonaSpecialty(),
                'days_since' => $daysSince,
            ];
        }

        return new JsonResponse($result);
    }

    #[Route('/recent-topics', name: 'api_worker_recent_topics', methods: ['GET'])]
    public function getRecentTopics(Request $request): JsonResponse
    {
        $this->requireWorkerKey($request);

        $days = max(1, (int) $request->query->get('days', '14'));
        $rows = $this->debateRepository->findRecentForWorker($days);

        $result = array_map(static function (array $row): array {
            $date = $row['dayDate'];
            return [
                'title'    => $row['title'],
                'day_date' => $date instanceof \DateTimeInterface
                    ? $date->format('Y-m-d')
                    : (string) $date,
            ];
        }, $rows);

        return new JsonResponse($result);
    }

    #[Route('/publish', name: 'api_worker_publish', methods: ['POST'])]
    public function publish(Request $request): JsonResponse
    {
        $this->requireWorkerKey($request);

        $data = json_decode($request->getContent(), true) ?? [];
        $debates = $data['debates'] ?? [];
        $runId = $data['run_id'] ?? $data['runId'] ?? \Ramsey\Uuid\Uuid::uuid4()->toString();

        if (empty($debates)) {
            throw new \InvalidArgumentException('debates array is required');
        }

        $result = $this->workerService->publishDebates($debates, $runId);

        return new JsonResponse($result, 201);
    }
}
