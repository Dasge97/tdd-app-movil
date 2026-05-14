<?php

declare(strict_types=1);

namespace App\Controller\Admin;

use App\Entity\AdminAuditLog;
use App\Entity\User;
use App\Repository\AdminAuditLogRepository;
use App\Repository\DebateRepository;
use App\Repository\UserRepository;
use App\Service\AdminService;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\RedirectResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpFoundation\Session\SessionInterface;
use Symfony\Component\Routing\Attribute\Route;

#[Route('/admin')]
class AdminController extends AbstractController
{
    public function __construct(
        private readonly UserRepository $userRepository,
        private readonly AdminService $adminService,
        private readonly DebateRepository $debateRepository,
        private readonly AdminAuditLogRepository $auditLogRepository
    ) {
    }

    private function getAdminUser(Request $request): ?User
    {
        $session = $request->getSession();
        $adminId = $session->get('admin_user_id');
        if ($adminId === null) {
            return null;
        }
        $user = $this->userRepository->find($adminId);
        if ($user === null || $user->getRole() !== 'admin') {
            return null;
        }
        return $user;
    }

    private function requireAdminSession(Request $request): ?Response
    {
        if ($this->getAdminUser($request) === null) {
            return new RedirectResponse('/admin/login');
        }
        return null;
    }

    #[Route('/login', name: 'admin_login', methods: ['GET'])]
    public function loginForm(): Response
    {
        return $this->render('admin/login.html.twig');
    }

    #[Route('/login', name: 'admin_login_post', methods: ['POST'])]
    public function login(Request $request): Response
    {
        $email = $request->request->get('email', '');
        $password = $request->request->get('password', '');

        $user = $this->userRepository->findByEmail($email);

        if ($user === null || !password_verify($password, $user->getPasswordHash()) || $user->getRole() !== 'admin') {
            return $this->render('admin/login.html.twig', [
                'error' => 'Invalid credentials or insufficient permissions',
            ]);
        }

        $request->getSession()->set('admin_user_id', $user->getId());

        return new RedirectResponse('/admin/dashboard');
    }

    #[Route('/logout', name: 'admin_logout', methods: ['GET', 'POST'])]
    public function logout(Request $request): Response
    {
        $request->getSession()->remove('admin_user_id');
        return new RedirectResponse('/admin/login');
    }

    #[Route('/dashboard', name: 'admin_dashboard', methods: ['GET'])]
    public function dashboard(Request $request): Response
    {
        if ($redirect = $this->requireAdminSession($request)) {
            return $redirect;
        }

        $todayDebates = $this->debateRepository->findTodaysDebates();
        $workerConfig = $this->adminService->getWorkerConfig();
        $recentRuns = $this->adminService->getWorkerRuns(5);

        // Quick stats
        $totalUsers = count($this->adminService->getUsers(1));

        return $this->render('admin/dashboard.html.twig', [
            'admin'         => $this->getAdminUser($request),
            'todayDebates'  => count($todayDebates),
            'workerConfig'  => $workerConfig,
            'recentRuns'    => $recentRuns,
            'totalUsers'    => $totalUsers,
        ]);
    }

    #[Route('/worker', name: 'admin_worker', methods: ['GET'])]
    public function worker(Request $request): Response
    {
        if ($redirect = $this->requireAdminSession($request)) {
            return $redirect;
        }

        $config = $this->adminService->getWorkerConfig();
        $runs = $this->adminService->getWorkerRuns(20);

        return $this->render('admin/worker.html.twig', [
            'admin'  => $this->getAdminUser($request),
            'config' => $config,
            'runs'   => $runs,
        ]);
    }

    #[Route('/worker/config', name: 'admin_worker_config_save', methods: ['POST'])]
    public function saveWorkerConfig(Request $request): Response
    {
        if ($redirect = $this->requireAdminSession($request)) {
            return $redirect;
        }

        $data = [
            'schedule'          => $request->request->get('schedule'),
            'enabled'           => $request->request->has('enabled'),
            'dedupDays'         => (int) $request->request->get('dedupDays', 14),
            'rotationLimitDays' => (int) $request->request->get('rotationLimitDays', 3),
            'targetDebates'     => (int) $request->request->get('targetDebates', 5),
            'opencodeModel'     => $request->request->get('opencodeModel'),
            'opencodeProvider'  => $request->request->get('opencodeProvider'),
        ];

        $this->adminService->updateWorkerConfig($data);

        $admin = $this->getAdminUser($request);
        $log = new AdminAuditLog();
        $log->setAdminUser($admin);
        $log->setActionType('update_worker_config');
        $log->setEntityType('WorkerConfig');
        $log->setEntityId(1);
        $log->setPayload($data);
        $this->auditLogRepository->save($log);

        return new RedirectResponse('/admin/worker');
    }

    #[Route('/worker/trigger', name: 'admin_worker_trigger', methods: ['POST'])]
    public function triggerWorker(Request $request): Response
    {
        if ($redirect = $this->requireAdminSession($request)) {
            return $redirect;
        }

        $this->adminService->triggerWorker();

        $admin = $this->getAdminUser($request);
        $log = new AdminAuditLog();
        $log->setAdminUser($admin);
        $log->setActionType('trigger_worker');
        $log->setEntityType('WorkerConfig');
        $log->setEntityId(1);
        $log->setPayload([]);
        $this->auditLogRepository->save($log);

        return new RedirectResponse('/admin/worker');
    }

    #[Route('/users', name: 'admin_users', methods: ['GET'])]
    public function users(Request $request): Response
    {
        if ($redirect = $this->requireAdminSession($request)) {
            return $redirect;
        }

        $page = max(1, (int) $request->query->get('page', '1'));
        $search = $request->query->get('search');
        $users = $this->adminService->getUsers($page, $search);

        return $this->render('admin/users.html.twig', [
            'admin'  => $this->getAdminUser($request),
            'users'  => $users,
            'page'   => $page,
            'search' => $search,
        ]);
    }

    #[Route('/users/{id}/status', name: 'admin_users_status', methods: ['POST'], requirements: ['id' => '\d+'])]
    public function updateUserStatus(int $id, Request $request): Response
    {
        if ($redirect = $this->requireAdminSession($request)) {
            return $redirect;
        }

        $status = $request->request->get('status', 'active');
        $user = $this->adminService->updateUserStatus($id, $status);

        $admin = $this->getAdminUser($request);
        $log = new AdminAuditLog();
        $log->setAdminUser($admin);
        $log->setActionType('update_user_status');
        $log->setEntityType('User');
        $log->setEntityId($id);
        $log->setPayload(['status' => $status]);
        $this->auditLogRepository->save($log);

        return new RedirectResponse('/admin/users');
    }

    #[Route('/audit-log', name: 'admin_audit_log', methods: ['GET'])]
    public function auditLog(Request $request): Response
    {
        if ($redirect = $this->requireAdminSession($request)) {
            return $redirect;
        }

        $page = max(1, (int) $request->query->get('page', '1'));
        $logs = $this->adminService->getAuditLog($page);

        return $this->render('admin/audit.html.twig', [
            'admin' => $this->getAdminUser($request),
            'logs'  => $logs,
            'page'  => $page,
        ]);
    }
}
