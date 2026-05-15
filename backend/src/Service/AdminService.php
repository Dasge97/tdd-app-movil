<?php

declare(strict_types=1);

namespace App\Service;

use App\Entity\User;
use App\Entity\WorkerConfig;
use App\Repository\AdminAuditLogRepository;
use App\Repository\UserRepository;
use App\Repository\WorkerConfigRepository;
use App\Repository\WorkerRunRepository;

class AdminService
{
    private const PAGE_SIZE = 30;

    public function __construct(
        private readonly WorkerConfigRepository $workerConfigRepository,
        private readonly WorkerRunRepository $workerRunRepository,
        private readonly AdminAuditLogRepository $auditLogRepository,
        private readonly UserRepository $userRepository
    ) {
    }

    public function getWorkerConfig(): WorkerConfig
    {
        return $this->workerConfigRepository->getConfig();
    }

    public function updateWorkerConfig(array $data): WorkerConfig
    {
        $config = $this->workerConfigRepository->getConfig();

        if (isset($data['schedule'])) {
            $config->setSchedule($data['schedule']);
        }
        if (isset($data['enabled'])) {
            $config->setEnabled((bool) $data['enabled']);
        }
        if (isset($data['dedupDays'])) {
            $config->setDedupDays((int) $data['dedupDays']);
        }
        if (isset($data['rotationLimitDays'])) {
            $config->setRotationLimitDays((int) $data['rotationLimitDays']);
        }
        if (isset($data['targetDebates'])) {
            $config->setTargetDebates((int) $data['targetDebates']);
        }
        if (isset($data['rules'])) {
            $config->setRules($data['rules']);
        }
        if (isset($data['opencodeModel'])) {
            $config->setOpencodeModel($data['opencodeModel']);
        }
        if (isset($data['opencodeProvider'])) {
            $config->setOpencodeProvider($data['opencodeProvider']);
        }

        $config->setUpdatedAt(new \DateTime());
        $this->workerConfigRepository->save($config);

        return $config;
    }

    public function triggerWorker(): void
    {
        $config = $this->workerConfigRepository->getConfig();
        $config->setTriggerPending(true);
        $config->setUpdatedAt(new \DateTime());
        $this->workerConfigRepository->save($config);
    }

    public function resetTriggerPending(): void
    {
        $config = $this->workerConfigRepository->getConfig();
        $config->setTriggerPending(false);
        $config->setUpdatedAt(new \DateTime());
        $this->workerConfigRepository->save($config);
    }

    public function getWorkerRuns(int $limit = 20): array
    {
        return $this->workerRunRepository->findRecent($limit);
    }

    public function getAuditLog(int $page): array
    {
        return $this->auditLogRepository->findPaginated($page, self::PAGE_SIZE);
    }

    public function getUsers(int $page, ?string $search = null): array
    {
        $offset = ($page - 1) * self::PAGE_SIZE;
        $qb = $this->userRepository->createQueryBuilder('u');

        if ($search !== null && $search !== '') {
            $qb->where('u.username LIKE :search OR u.email LIKE :search')
               ->setParameter('search', '%' . $search . '%');
        }

        return $qb->orderBy('u.createdAt', 'DESC')
            ->setMaxResults(self::PAGE_SIZE)
            ->setFirstResult($offset)
            ->getQuery()
            ->getResult();
    }

    public function updateUserStatus(int $userId, string $status): User
    {
        if (!in_array($status, ['active', 'suspended'], true)) {
            throw new \InvalidArgumentException('status must be active or suspended');
        }

        $user = $this->userRepository->find($userId);
        if ($user === null) {
            throw new \RuntimeException('NOT_FOUND: user not found');
        }

        $user->setStatus($status);
        $this->userRepository->save($user);

        return $user;
    }
}
