<?php

declare(strict_types=1);

namespace App\Controller\Api;

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
        private readonly string $workerApiKey
    ) {
    }

    #[Route('/publish', name: 'api_worker_publish', methods: ['POST'])]
    public function publish(Request $request): JsonResponse
    {
        $apiKey = $request->headers->get('X-Worker-Key', '');

        if ($apiKey !== $this->workerApiKey || empty($this->workerApiKey)) {
            throw new \RuntimeException('UNAUTHORIZED: invalid worker API key');
        }

        $data = json_decode($request->getContent(), true) ?? [];
        $debates = $data['debates'] ?? [];
        $runId = $data['runId'] ?? \Ramsey\Uuid\Uuid::uuid4()->toString();

        if (empty($debates)) {
            throw new \InvalidArgumentException('debates array is required');
        }

        $result = $this->workerService->publishDebates($debates, $runId);

        return new JsonResponse($result, 201);
    }
}
