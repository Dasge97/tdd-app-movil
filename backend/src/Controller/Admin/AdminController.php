<?php

declare(strict_types=1);

namespace App\Controller\Admin;

use App\Entity\User;
use App\Repository\UserRepository;
use App\Service\AdminService;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\RedirectResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

#[Route('/admin')]
class AdminController extends AbstractController
{
    public function __construct(
        private readonly UserRepository $userRepository,
        private readonly AdminService $adminService,
    ) {
    }

    // ── Auth ─────────────────────────────────────────────────────────────────────

    private function getAdminUser(Request $request): ?User
    {
        $adminId = $request->getSession()->get('admin_user_id');
        if ($adminId === null) { return null; }
        $user = $this->userRepository->find($adminId);
        return ($user !== null && $user->getRole() === 'admin') ? $user : null;
    }

    private function requireAdmin(Request $request): ?Response
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
        $user = $this->userRepository->findByEmail($request->request->get('email', ''));

        if ($user === null || !password_verify($request->request->get('password', ''), $user->getPasswordHash()) || $user->getRole() !== 'admin') {
            return $this->render('admin/login.html.twig', ['error' => 'Credenciales incorrectas o permisos insuficientes']);
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

    // ── Dashboard ────────────────────────────────────────────────────────────────

    #[Route('/dashboard', name: 'admin_dashboard', methods: ['GET'])]
    public function dashboard(Request $request): Response
    {
        if ($r = $this->requireAdmin($request)) { return $r; }

        return $this->render('admin/dashboard.html.twig', [
            'admin' => $this->getAdminUser($request),
            'stats' => $this->adminService->getStats(),
        ]);
    }

    // ── Worker ───────────────────────────────────────────────────────────────────

    #[Route('/worker', name: 'admin_worker', methods: ['GET'])]
    public function worker(Request $request): Response
    {
        if ($r = $this->requireAdmin($request)) { return $r; }

        return $this->render('admin/worker.html.twig', [
            'admin'  => $this->getAdminUser($request),
            'config' => $this->adminService->getWorkerConfig(),
            'runs'   => $this->adminService->getWorkerRuns(20),
        ]);
    }

    #[Route('/worker/config', name: 'admin_worker_config_save', methods: ['POST'])]
    public function saveWorkerConfig(Request $request): Response
    {
        if ($r = $this->requireAdmin($request)) { return $r; }

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
        $this->adminService->logAction($this->getAdminUser($request), 'update_worker_config', 'WorkerConfig', 1, $data);

        return new RedirectResponse('/admin/worker');
    }

    #[Route('/worker/trigger', name: 'admin_worker_trigger', methods: ['POST'])]
    public function triggerWorker(Request $request): Response
    {
        if ($r = $this->requireAdmin($request)) { return $r; }

        $this->adminService->triggerWorker();
        $this->adminService->logAction($this->getAdminUser($request), 'trigger_worker', 'WorkerConfig', 1);

        return new RedirectResponse('/admin/worker');
    }

    // ── Usuarios ─────────────────────────────────────────────────────────────────

    #[Route('/users', name: 'admin_users', methods: ['GET'])]
    public function users(Request $request): Response
    {
        if ($r = $this->requireAdmin($request)) { return $r; }

        $page   = max(1, (int) $request->query->get('page', '1'));
        $search = $request->query->get('search');

        return $this->render('admin/users.html.twig', [
            'admin'  => $this->getAdminUser($request),
            'users'  => $this->adminService->getUsers($page, $search),
            'page'   => $page,
            'search' => $search,
        ]);
    }

    #[Route('/users/{id}', name: 'admin_user_detail', methods: ['GET'], requirements: ['id' => '\d+'])]
    public function userDetail(int $id, Request $request): Response
    {
        if ($r = $this->requireAdmin($request)) { return $r; }

        return $this->render('admin/user-detail.html.twig', [
            'admin' => $this->getAdminUser($request),
            ...$this->adminService->getUserDetail($id),
        ]);
    }

    #[Route('/users/{id}/status', name: 'admin_users_status', methods: ['POST'], requirements: ['id' => '\d+'])]
    public function updateUserStatus(int $id, Request $request): Response
    {
        if ($r = $this->requireAdmin($request)) { return $r; }

        $status = $request->request->get('status', 'active');
        $user   = $this->adminService->updateUserStatus($id, $status);
        $this->adminService->logAction($this->getAdminUser($request), 'update_user_status', 'User', $id, ['status' => $status]);

        $redirect = $request->request->get('redirect', '/admin/users');
        return new RedirectResponse($redirect);
    }

    // ── Moderación (shadow ban) ───────────────────────────────────────────────────

    #[Route('/moderation', name: 'admin_moderation', methods: ['GET'])]
    public function moderation(Request $request): Response
    {
        if ($r = $this->requireAdmin($request)) { return $r; }

        return $this->render('admin/moderation.html.twig', [
            'admin' => $this->getAdminUser($request),
            'users' => $this->adminService->getShadowBannedUsers(),
        ]);
    }

    #[Route('/moderation/{id}/unban', name: 'admin_moderation_unban', methods: ['POST'], requirements: ['id' => '\d+'])]
    public function unban(int $id, Request $request): Response
    {
        if ($r = $this->requireAdmin($request)) { return $r; }

        $this->adminService->setShadowBan($id, false);
        $this->adminService->logAction($this->getAdminUser($request), 'unban_user', 'User', $id);

        return new RedirectResponse('/admin/moderation');
    }

    #[Route('/moderation/{id}/ban', name: 'admin_moderation_ban', methods: ['POST'], requirements: ['id' => '\d+'])]
    public function ban(int $id, Request $request): Response
    {
        if ($r = $this->requireAdmin($request)) { return $r; }

        $this->adminService->setShadowBan($id, true);
        $this->adminService->logAction($this->getAdminUser($request), 'shadow_ban_user', 'User', $id);

        return new RedirectResponse($request->request->get('redirect', '/admin/moderation'));
    }

    // ── Debates ───────────────────────────────────────────────────────────────────

    #[Route('/debates', name: 'admin_debates', methods: ['GET'])]
    public function debates(Request $request): Response
    {
        if ($r = $this->requireAdmin($request)) { return $r; }

        $page       = max(1, (int) $request->query->get('page', '1'));
        $date       = $request->query->get('date');
        $persona    = $request->query->get('persona');
        $authorType = $request->query->get('authorType');

        return $this->render('admin/debates.html.twig', [
            'admin'      => $this->getAdminUser($request),
            'debates'    => $this->adminService->getDebates($page, $date, $persona, $authorType),
            'page'       => $page,
            'date'       => $date,
            'persona'    => $persona,
            'authorType' => $authorType,
        ]);
    }

    #[Route('/debates/{id}', name: 'admin_debate_detail', methods: ['GET'], requirements: ['id' => '\d+'])]
    public function debateDetail(int $id, Request $request): Response
    {
        if ($r = $this->requireAdmin($request)) { return $r; }

        return $this->render('admin/debate-detail.html.twig', [
            'admin'  => $this->getAdminUser($request),
            'debate' => $this->adminService->getDebate($id),
        ]);
    }

    #[Route('/debates/{id}/delete', name: 'admin_debate_delete', methods: ['POST'], requirements: ['id' => '\d+'])]
    public function deleteDebate(int $id, Request $request): Response
    {
        if ($r = $this->requireAdmin($request)) { return $r; }

        $this->adminService->deleteDebate($id);
        $this->adminService->logAction($this->getAdminUser($request), 'delete_debate', 'Debate', $id);

        return new RedirectResponse('/admin/debates');
    }

    // ── Propuestas de usuarios ────────────────────────────────────────────────────

    #[Route('/propuestas', name: 'admin_propuestas', methods: ['GET'])]
    public function propuestas(Request $request): Response
    {
        if ($r = $this->requireAdmin($request)) { return $r; }

        $page = max(1, (int) $request->query->get('page', '1'));

        return $this->render('admin/propuestas.html.twig', [
            'admin'    => $this->getAdminUser($request),
            'debates'  => $this->adminService->getUserProposals($page),
            'page'     => $page,
        ]);
    }

    #[Route('/propuestas/{id}/delete', name: 'admin_propuestas_delete', methods: ['POST'], requirements: ['id' => '\d+'])]
    public function deletePropuesta(int $id, Request $request): Response
    {
        if ($r = $this->requireAdmin($request)) { return $r; }

        $this->adminService->deleteDebate($id);
        $this->adminService->logAction($this->getAdminUser($request), 'reject_proposal', 'Debate', $id);

        return new RedirectResponse('/admin/propuestas');
    }

    // ── Personajes IA ─────────────────────────────────────────────────────────────

    #[Route('/personas', name: 'admin_personas', methods: ['GET'])]
    public function personas(Request $request): Response
    {
        if ($r = $this->requireAdmin($request)) { return $r; }

        return $this->render('admin/personas.html.twig', [
            'admin'    => $this->getAdminUser($request),
            'personas' => $this->adminService->getPersonas(),
        ]);
    }

    #[Route('/personas/{id}/edit', name: 'admin_personas_edit', methods: ['POST'], requirements: ['id' => '\d+'])]
    public function editPersona(int $id, Request $request): Response
    {
        if ($r = $this->requireAdmin($request)) { return $r; }

        $traitsRaw = $request->request->get('profileTraits', '');
        $traits    = array_values(array_filter(array_map('trim', explode(',', $traitsRaw))));

        $data = [
            'bio'              => $request->request->get('bio'),
            'profileTagline'   => $request->request->get('profileTagline'),
            'personaSpecialty' => $request->request->get('personaSpecialty'),
            'profileTraits'    => $traits,
        ];

        $this->adminService->updatePersona($id, $data);
        $this->adminService->logAction($this->getAdminUser($request), 'update_persona', 'User', $id, $data);

        return new RedirectResponse('/admin/personas');
    }

    // ── Comentarios ───────────────────────────────────────────────────────────────

    #[Route('/comments', name: 'admin_comments', methods: ['GET'])]
    public function comments(Request $request): Response
    {
        if ($r = $this->requireAdmin($request)) { return $r; }

        $page     = max(1, (int) $request->query->get('page', '1'));
        $username = $request->query->get('username');
        $debateId = $request->query->get('debateId') ? (int) $request->query->get('debateId') : null;

        return $this->render('admin/comments.html.twig', [
            'admin'    => $this->getAdminUser($request),
            'comments' => $this->adminService->getComments($page, $username, $debateId),
            'page'     => $page,
            'username' => $username,
            'debateId' => $debateId,
        ]);
    }

    #[Route('/comments/{id}/delete', name: 'admin_comment_delete', methods: ['POST'], requirements: ['id' => '\d+'])]
    public function deleteComment(int $id, Request $request): Response
    {
        if ($r = $this->requireAdmin($request)) { return $r; }

        $this->adminService->deleteComment($id);
        $this->adminService->logAction($this->getAdminUser($request), 'delete_comment', 'Comment', $id);

        $redirect = $request->request->get('redirect', '/admin/comments');
        return new RedirectResponse($redirect);
    }

    // ── Audit log ─────────────────────────────────────────────────────────────────

    #[Route('/audit-log', name: 'admin_audit_log', methods: ['GET'])]
    public function auditLog(Request $request): Response
    {
        if ($r = $this->requireAdmin($request)) { return $r; }

        $page = max(1, (int) $request->query->get('page', '1'));

        return $this->render('admin/audit.html.twig', [
            'admin' => $this->getAdminUser($request),
            'logs'  => $this->adminService->getAuditLog($page),
            'page'  => $page,
        ]);
    }
}
