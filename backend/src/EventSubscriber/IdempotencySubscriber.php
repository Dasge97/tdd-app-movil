<?php

declare(strict_types=1);

namespace App\EventSubscriber;

use App\Entity\User;
use App\Repository\IdempotencyKeyRepository;
use Symfony\Component\EventDispatcher\EventSubscriberInterface;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpKernel\Event\RequestEvent;
use Symfony\Component\HttpKernel\Event\ResponseEvent;
use Symfony\Component\HttpKernel\KernelEvents;

class IdempotencySubscriber implements EventSubscriberInterface
{
    private const IDEMPOTENT_ROUTES = [
        '/api/v1/debates',
        '/api/v1/comments',
    ];

    private const CHAT_MESSAGE_PATTERN = '#^/api/v1/chat/conversations/\d+/messages$#';

    public function __construct(
        private readonly IdempotencyKeyRepository $idempotencyKeyRepository
    ) {
    }

    public static function getSubscribedEvents(): array
    {
        return [
            KernelEvents::REQUEST  => ['onRequest', 5],
            KernelEvents::RESPONSE => ['onResponse', 0],
        ];
    }

    public function onRequest(RequestEvent $event): void
    {
        if (!$event->isMainRequest()) {
            return;
        }

        $request = $event->getRequest();

        if ($request->getMethod() !== Request::METHOD_POST) {
            return;
        }

        if (!$this->isIdempotentRoute($request)) {
            return;
        }

        $idempotencyKey = $request->headers->get('Idempotency-Key');
        if ($idempotencyKey === null || $idempotencyKey === '') {
            return;
        }

        /** @var User|null $user */
        $user = $request->attributes->get('currentUser');
        $userId = $user ? (string) $user->getId() : 'anonymous';

        $keyHash = hash('sha256', $idempotencyKey . $userId);
        $request->attributes->set('idempotencyHash', $keyHash);

        $existing = $this->idempotencyKeyRepository->findByHash($keyHash);
        if ($existing !== null && $existing->getExpiresAt() > new \DateTime()) {
            $response = new JsonResponse(
                $existing->getResponseBody(),
                $existing->getResponseStatus()
            );
            $response->headers->set('X-Idempotency-Replayed', 'true');
            $event->setResponse($response);
        }
    }

    public function onResponse(ResponseEvent $event): void
    {
        if (!$event->isMainRequest()) {
            return;
        }

        $request = $event->getRequest();
        $keyHash = $request->attributes->get('idempotencyHash');

        if ($keyHash === null) {
            return;
        }

        $response = $event->getResponse();

        // Only cache successful POST responses
        if ($response->getStatusCode() < 200 || $response->getStatusCode() >= 300) {
            return;
        }

        $existing = $this->idempotencyKeyRepository->findByHash($keyHash);
        if ($existing !== null) {
            return; // Already stored
        }

        $content = $response->getContent();
        $body = json_decode($content ?: '{}', true) ?? [];
        $expiresAt = new \DateTime('+24 hours');

        try {
            $this->idempotencyKeyRepository->save($keyHash, $response->getStatusCode(), $body, $expiresAt);
        } catch (\Exception) {
            // Silently ignore duplicate key errors
        }
    }

    private function isIdempotentRoute(Request $request): bool
    {
        $path = $request->getPathInfo();

        foreach (self::IDEMPOTENT_ROUTES as $route) {
            if ($path === $route) {
                return true;
            }
        }

        if (preg_match(self::CHAT_MESSAGE_PATTERN, $path)) {
            return true;
        }

        return false;
    }
}
