<?php

declare(strict_types=1);

namespace App\Controller\Api;

use App\Entity\AdminAuditLog;
use App\Entity\User;
use App\Entity\WorkerConfig;
use App\Entity\WorkerRun;
use App\Repository\AdminAuditLogRepository;
use App\Serializer\UserNormalizer;
use App\Service\AdminService;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\Routing\Attribute\Route;

#[Route('/api/v1/admin')]
class AdminApiController extends AbstractController
{
    public function __construct(
        private readonly AdminService $adminService,
        private readonly UserNormalizer $userNormalizer,
        private readonly AdminAuditLogRepository $auditLogRepository
    ) {
    }

    private function requireAdmin(Request $request): User
    {
        /** @var User|null $user */
        $user = $request->attributes->get('currentUser');
        if ($user === null || $user->getRole() !== 'admin') {
            throw new \RuntimeException('FORBIDDEN: admin access required');
        }
        return $user;
    }

    #[Route('/worker/config', name: 'api_admin_worker_config_get', methods: ['GET'])]
    public function getWorkerConfig(Request $request): JsonResponse
    {
        $this->requireAdmin($request);
        $config = $this->adminService->getWorkerConfig();
        return new JsonResponse($this->normalizeConfig($config));
    }

    #[Route('/worker/config', name: 'api_admin_worker_config_update', methods: ['PUT'])]
    public function updateWorkerConfig(Request $request): JsonResponse
    {
        $admin = $this->requireAdmin($request);
        $data = json_decode($request->getContent(), true) ?? [];
        $config = $this->adminService->updateWorkerConfig($data);

        $this->logAction($admin, 'update_worker_config', 'WorkerConfig', 1, $data);

        return new JsonResponse($this->normalizeConfig($config));
    }

    #[Route('/worker/trigger', name: 'api_admin_worker_trigger', methods: ['POST'])]
    public function triggerWorker(Request $request): JsonResponse
    {
        $admin = $this->requireAdmin($request);
        $this->adminService->triggerWorker();
        $this->logAction($admin, 'trigger_worker', 'WorkerConfig', 1, []);

        return new JsonResponse(['success' => true]);
    }

    #[Route('/worker/runs', name: 'api_admin_worker_runs', methods: ['GET'])]
    public function getWorkerRuns(Request $request): JsonResponse
    {
        $this->requireAdmin($request);
        $runs = $this->adminService->getWorkerRuns();

        return new JsonResponse(
            array_map(fn(WorkerRun $r) => $this->normalizeRun($r), $runs)
        );
    }

    #[Route('/audit-log', name: 'api_admin_audit_log', methods: ['GET'])]
    public function getAuditLog(Request $request): JsonResponse
    {
        $this->requireAdmin($request);
        $page = max(1, (int) $request->query->get('page', '1'));
        $logs = $this->adminService->getAuditLog($page);

        return new JsonResponse(
            array_map(fn(AdminAuditLog $l) => $this->normalizeLog($l), $logs)
        );
    }

    #[Route('/users', name: 'api_admin_users', methods: ['GET'])]
    public function getUsers(Request $request): JsonResponse
    {
        $this->requireAdmin($request);
        $page = max(1, (int) $request->query->get('page', '1'));
        $search = $request->query->get('search');

        $users = $this->adminService->getUsers($page, $search);

        return new JsonResponse($this->userNormalizer->normalizeMany($users));
    }

    #[Route('/users/{id}/status', name: 'api_admin_users_status', methods: ['PUT'], requirements: ['id' => '\d+'])]
    public function updateUserStatus(int $id, Request $request): JsonResponse
    {
        $admin = $this->requireAdmin($request);
        $data = json_decode($request->getContent(), true) ?? [];
        $status = $data['status'] ?? '';

        $user = $this->adminService->updateUserStatus($id, $status);
        $this->logAction($admin, 'update_user_status', 'User', $id, ['status' => $status]);

        return new JsonResponse($this->userNormalizer->normalize($user));
    }

    private function logAction(User $admin, string $action, string $entity, int $entityId, array $payload): void
    {
        $log = new AdminAuditLog();
        $log->setAdminUser($admin);
        $log->setActionType($action);
        $log->setEntityType($entity);
        $log->setEntityId($entityId);
        $log->setPayload($payload);
        $this->auditLogRepository->save($log);
    }

    private function normalizeConfig(WorkerConfig $config): array
    {
        return [
            'schedule'          => $config->getSchedule(),
            'enabled'           => $config->isEnabled(),
            'triggerPending'    => $config->isTriggerPending(),
            'dedupDays'         => $config->getDedupDays(),
            'rotationLimitDays' => $config->getRotationLimitDays(),
            'targetDebates'     => $config->getTargetDebates(),
            'rules'             => $config->getRules(),
            'opencodeModel'     => $config->getOpencodeModel(),
            'opencodeProvider'  => $config->getOpencodeProvider(),
            'updatedAt'         => $config->getUpdatedAt()?->format(\DateTimeInterface::ATOM),
        ];
    }

    private function normalizeRun(WorkerRun $run): array
    {
        return [
            'id'               => $run->getId(),
            'status'           => $run->getStatus(),
            'debatesGenerated' => $run->getDebatesGenerated(),
            'errorMessage'     => $run->getErrorMessage(),
            'startedAt'        => $run->getStartedAt()->format(\DateTimeInterface::ATOM),
            'finishedAt'       => $run->getFinishedAt()?->format(\DateTimeInterface::ATOM),
            'meta'             => $run->getMeta(),
        ];
    }

    private function normalizeLog(AdminAuditLog $log): array
    {
        return [
            'id'         => $log->getId(),
            'actionType' => $log->getActionType(),
            'entityType' => $log->getEntityType(),
            'entityId'   => $log->getEntityId(),
            'payload'    => $log->getPayload(),
            'createdAt'  => $log->getCreatedAt()->format(\DateTimeInterface::ATOM),
            'adminUser'  => [
                'id'       => $log->getAdminUser()->getId(),
                'username' => $log->getAdminUser()->getUsername(),
            ],
        ];
    }
}
