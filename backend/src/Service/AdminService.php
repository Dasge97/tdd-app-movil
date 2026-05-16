<?php

declare(strict_types=1);

namespace App\Service;

use App\Entity\AdminAuditLog;
use App\Entity\Comment;
use App\Entity\Debate;
use App\Entity\User;
use App\Entity\WorkerConfig;
use App\Repository\AdminAuditLogRepository;
use App\Repository\CommentRepository;
use App\Repository\DebateRepository;
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
        private readonly UserRepository $userRepository,
        private readonly DebateRepository $debateRepository,
        private readonly CommentRepository $commentRepository
    ) {
    }

    // ── Worker ───────────────────────────────────────────────────────────────────

    public function getWorkerConfig(): WorkerConfig
    {
        return $this->workerConfigRepository->getConfig();
    }

    public function updateWorkerConfig(array $data): WorkerConfig
    {
        $config = $this->workerConfigRepository->getConfig();

        if (isset($data['schedule']))          { $config->setSchedule($data['schedule']); }
        if (isset($data['enabled']))           { $config->setEnabled((bool) $data['enabled']); }
        if (isset($data['dedupDays']))         { $config->setDedupDays((int) $data['dedupDays']); }
        if (isset($data['rotationLimitDays'])) { $config->setRotationLimitDays((int) $data['rotationLimitDays']); }
        if (isset($data['targetDebates']))     { $config->setTargetDebates((int) $data['targetDebates']); }
        if (isset($data['rules']))             { $config->setRules($data['rules']); }
        if (isset($data['opencodeModel']))     { $config->setOpencodeModel($data['opencodeModel']); }
        if (isset($data['opencodeProvider']))  { $config->setOpencodeProvider($data['opencodeProvider']); }

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

    // ── Estadísticas ─────────────────────────────────────────────────────────────

    public function getStats(): array
    {
        $em = $this->userRepository->getEntityManager();

        $totalUsers = (int) $em->createQuery('SELECT COUNT(u.id) FROM App\Entity\User u WHERE u.isAiPersona = false')->getSingleScalarResult();
        $totalDebates = (int) $em->createQuery('SELECT COUNT(d.id) FROM App\Entity\Debate d')->getSingleScalarResult();
        $totalComments = (int) $em->createQuery('SELECT COUNT(c.id) FROM App\Entity\Comment c')->getSingleScalarResult();

        $today = (new \DateTime())->format('Y-m-d');
        $todayDebates = (int) $em->createQuery('SELECT COUNT(d.id) FROM App\Entity\Debate d WHERE d.dayDate = :today')
            ->setParameter('today', $today)->getSingleScalarResult();

        $since7 = new \DateTime('-7 days');
        $activeUsers = (int) $em->createQuery('SELECT COUNT(DISTINCT c.user) FROM App\Entity\Comment c WHERE c.createdAt >= :since')
            ->setParameter('since', $since7)->getSingleScalarResult();

        $since30 = new \DateTime('-30 days');
        $newUsers = (int) $em->createQuery('SELECT COUNT(u.id) FROM App\Entity\User u WHERE u.createdAt >= :since AND u.isAiPersona = false')
            ->setParameter('since', $since30)->getSingleScalarResult();

        $shadowBanned = (int) $em->createQuery('SELECT COUNT(u.id) FROM App\Entity\User u WHERE u.isShadowBanned = true')->getSingleScalarResult();

        $userProposals = (int) $em->createQuery("SELECT COUNT(d.id) FROM App\Entity\Debate d WHERE d.authorType = 'user'")->getSingleScalarResult();

        $workerConfig = $this->workerConfigRepository->getConfig();
        $recentRuns = $this->workerRunRepository->findRecent(10);
        $okRuns = count(array_filter($recentRuns, fn($r) => $r->getStatus() === 'ok'));
        $successRate = count($recentRuns) > 0 ? round($okRuns / count($recentRuns) * 100) : 0;

        return [
            'totalUsers'    => $totalUsers,
            'totalDebates'  => $totalDebates,
            'totalComments' => $totalComments,
            'todayDebates'  => $todayDebates,
            'activeUsers'   => $activeUsers,
            'newUsers'      => $newUsers,
            'shadowBanned'  => $shadowBanned,
            'userProposals' => $userProposals,
            'workerEnabled' => $workerConfig->isEnabled(),
            'workerSchedule' => $workerConfig->getSchedule(),
            'successRate'   => $successRate,
            'recentRuns'    => $recentRuns,
        ];
    }

    // ── Usuarios ─────────────────────────────────────────────────────────────────

    public function getUsers(int $page, ?string $search = null): array
    {
        $offset = ($page - 1) * self::PAGE_SIZE;
        $qb = $this->userRepository->createQueryBuilder('u')
            ->where('u.isAiPersona = false');

        if ($search !== null && $search !== '') {
            $qb->andWhere('u.username LIKE :search OR u.email LIKE :search')
               ->setParameter('search', '%' . $search . '%');
        }

        return $qb->orderBy('u.createdAt', 'DESC')
            ->setMaxResults(self::PAGE_SIZE)
            ->setFirstResult($offset)
            ->getQuery()
            ->getResult();
    }

    public function getUserDetail(int $userId): array
    {
        $user = $this->userRepository->find($userId);
        if ($user === null) {
            throw new \RuntimeException('Usuario no encontrado');
        }

        $debates = $this->debateRepository->createQueryBuilder('d')
            ->where('d.createdBy = :user')
            ->setParameter('user', $user)
            ->orderBy('d.createdAt', 'DESC')
            ->setMaxResults(20)
            ->getQuery()
            ->getResult();

        $comments = $this->commentRepository->createQueryBuilder('c')
            ->where('c.user = :user')
            ->setParameter('user', $user)
            ->orderBy('c.createdAt', 'DESC')
            ->setMaxResults(20)
            ->getQuery()
            ->getResult();

        return ['user' => $user, 'debates' => $debates, 'comments' => $comments];
    }

    public function updateUserStatus(int $userId, string $status): User
    {
        if (!in_array($status, ['active', 'suspended'], true)) {
            throw new \InvalidArgumentException('El estado debe ser active o suspended');
        }

        $user = $this->userRepository->find($userId);
        if ($user === null) {
            throw new \RuntimeException('NOT_FOUND: usuario no encontrado');
        }

        $user->setStatus($status);
        $this->userRepository->save($user);

        return $user;
    }

    // ── Moderación (shadow ban) ───────────────────────────────────────────────────

    public function getShadowBannedUsers(): array
    {
        return $this->userRepository->createQueryBuilder('u')
            ->where('u.isShadowBanned = true')
            ->andWhere('u.isAiPersona = false')
            ->orderBy('u.updatedAt', 'DESC')
            ->getQuery()
            ->getResult();
    }

    public function setShadowBan(int $userId, bool $banned): User
    {
        $user = $this->userRepository->find($userId);
        if ($user === null) {
            throw new \RuntimeException('Usuario no encontrado');
        }

        $user->setIsShadowBanned($banned);
        $this->userRepository->save($user);

        return $user;
    }

    // ── Debates ───────────────────────────────────────────────────────────────────

    public function getDebates(int $page, ?string $date = null, ?string $persona = null, ?string $authorType = null): array
    {
        $offset = ($page - 1) * self::PAGE_SIZE;
        $qb = $this->debateRepository->createQueryBuilder('d')
            ->leftJoin('d.createdBy', 'u')
            ->orderBy('d.createdAt', 'DESC')
            ->setMaxResults(self::PAGE_SIZE)
            ->setFirstResult($offset);

        if ($date !== null && $date !== '') {
            $qb->andWhere('d.dayDate = :date')->setParameter('date', $date);
        }
        if ($persona !== null && $persona !== '') {
            $qb->andWhere('u.username = :persona')->setParameter('persona', $persona);
        }
        if ($authorType !== null && $authorType !== '') {
            $qb->andWhere('d.authorType = :authorType')->setParameter('authorType', $authorType);
        }

        return $qb->getQuery()->getResult();
    }

    public function getDebate(int $id): Debate
    {
        $debate = $this->debateRepository->find($id);
        if ($debate === null) {
            throw new \RuntimeException('Debate no encontrado');
        }
        return $debate;
    }

    public function deleteDebate(int $id): void
    {
        $debate = $this->debateRepository->find($id);
        if ($debate === null) {
            throw new \RuntimeException('Debate no encontrado');
        }

        $em = $this->debateRepository->getEntityManager();
        $em->remove($debate);
        $em->flush();
    }

    // ── Propuestas de usuarios ────────────────────────────────────────────────────

    public function getUserProposals(int $page): array
    {
        $offset = ($page - 1) * self::PAGE_SIZE;

        return $this->debateRepository->createQueryBuilder('d')
            ->where("d.authorType = 'user'")
            ->orderBy('d.createdAt', 'DESC')
            ->setMaxResults(self::PAGE_SIZE)
            ->setFirstResult($offset)
            ->getQuery()
            ->getResult();
    }

    // ── Personajes IA ─────────────────────────────────────────────────────────────

    public function getPersonas(): array
    {
        return $this->userRepository->findAiPersonas();
    }

    public function updatePersona(int $id, array $data): User
    {
        $persona = $this->userRepository->find($id);
        if ($persona === null || !$persona->isAiPersona()) {
            throw new \RuntimeException('Personaje IA no encontrado');
        }

        if (isset($data['bio']))             { $persona->setBio($data['bio']); }
        if (isset($data['profileTagline']))  { $persona->setProfileTagline($data['profileTagline']); }
        if (isset($data['personaSpecialty'])) { $persona->setPersonaSpecialty($data['personaSpecialty']); }
        if (isset($data['profileTraits']) && is_array($data['profileTraits'])) {
            $persona->setProfileTraits($data['profileTraits']);
        }

        $this->userRepository->save($persona);

        return $persona;
    }

    // ── Comentarios ───────────────────────────────────────────────────────────────

    public function getComments(int $page, ?string $username = null, ?int $debateId = null): array
    {
        $offset = ($page - 1) * self::PAGE_SIZE;
        $qb = $this->commentRepository->createQueryBuilder('c')
            ->leftJoin('c.user', 'u')
            ->leftJoin('c.debate', 'd')
            ->orderBy('c.createdAt', 'DESC')
            ->setMaxResults(self::PAGE_SIZE)
            ->setFirstResult($offset);

        if ($username !== null && $username !== '') {
            $qb->andWhere('u.username LIKE :username')
               ->setParameter('username', '%' . $username . '%');
        }
        if ($debateId !== null) {
            $qb->andWhere('d.id = :debateId')
               ->setParameter('debateId', $debateId);
        }

        return $qb->getQuery()->getResult();
    }

    public function deleteComment(int $id): void
    {
        $comment = $this->commentRepository->find($id);
        if ($comment === null) {
            throw new \RuntimeException('Comentario no encontrado');
        }

        $em = $this->commentRepository->getEntityManager();
        $em->remove($comment);
        $em->flush();
    }

    // ── Audit log ─────────────────────────────────────────────────────────────────

    public function getAuditLog(int $page): array
    {
        return $this->auditLogRepository->findPaginated($page, self::PAGE_SIZE);
    }

    public function logAction(User $admin, string $action, string $entityType, int $entityId, array $payload = []): void
    {
        $log = new AdminAuditLog();
        $log->setAdminUser($admin);
        $log->setActionType($action);
        $log->setEntityType($entityType);
        $log->setEntityId($entityId);
        $log->setPayload($payload);
        $this->auditLogRepository->save($log);
    }
}
