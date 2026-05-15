<?php

declare(strict_types=1);

namespace App\EventSubscriber;

use App\Repository\UserRepository;
use App\Service\JwtService;
use Symfony\Component\EventDispatcher\EventSubscriberInterface;
use Symfony\Component\HttpKernel\Event\RequestEvent;
use Symfony\Component\HttpKernel\KernelEvents;

class JwtAuthSubscriber implements EventSubscriberInterface
{
    private const PUBLIC_ROUTES = [
        '/api/v1/auth/register',
        '/api/v1/auth/login',
        '/api/v1/auth/refresh',
        '/api/v1/worker/publish',
        '/api/v1/worker/config',
        '/api/v1/worker/trigger',
        '/api/v1/worker/ack',
        '/api/v1/worker/personas',
        '/api/v1/worker/recent-topics',
    ];

    public function __construct(
        private readonly JwtService $jwtService,
        private readonly UserRepository $userRepository
    ) {
    }

    public static function getSubscribedEvents(): array
    {
        return [
            KernelEvents::REQUEST => ['onKernelRequest', 10],
        ];
    }

    public function onKernelRequest(RequestEvent $event): void
    {
        if (!$event->isMainRequest()) {
            return;
        }

        $request = $event->getRequest();
        $path = $request->getPathInfo();

        // Only intercept /api/v1/*
        if (!str_starts_with($path, '/api/v1/')) {
            return;
        }

        // Skip public routes
        foreach (self::PUBLIC_ROUTES as $publicRoute) {
            if ($path === $publicRoute) {
                return;
            }
        }

        // OPTIONS preflight
        if ($request->getMethod() === 'OPTIONS') {
            return;
        }

        $authHeader = $request->headers->get('Authorization', '');
        if (!str_starts_with($authHeader, 'Bearer ')) {
            throw new \RuntimeException('UNAUTHORIZED: missing token');
        }

        $token = substr($authHeader, 7);

        try {
            $payload = $this->jwtService->decode($token);
        } catch (\Exception $e) {
            throw new \RuntimeException('UNAUTHORIZED: invalid token');
        }

        if (($payload['type'] ?? '') === 'refresh') {
            throw new \RuntimeException('UNAUTHORIZED: cannot use refresh token as access token');
        }

        $jti = $payload['jti'] ?? null;
        if ($jti !== null && $this->jwtService->isRevoked($jti)) {
            throw new \RuntimeException('UNAUTHORIZED: token revoked');
        }

        $userId = (int) ($payload['sub'] ?? 0);
        $user = $this->userRepository->find($userId);

        if ($user === null) {
            throw new \RuntimeException('UNAUTHORIZED: user not found');
        }

        if ($user->getStatus() === 'suspended') {
            throw new \RuntimeException('FORBIDDEN: account suspended');
        }

        $request->attributes->set('currentUser', $user);
        $request->attributes->set('jwtPayload', $payload);
    }
}
