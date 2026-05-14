<?php

declare(strict_types=1);

namespace App\EventSubscriber;

use Symfony\Component\EventDispatcher\EventSubscriberInterface;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpKernel\Event\ExceptionEvent;
use Symfony\Component\HttpKernel\KernelEvents;

class KernelExceptionSubscriber implements EventSubscriberInterface
{
    public static function getSubscribedEvents(): array
    {
        return [
            KernelEvents::EXCEPTION => ['onKernelException', 0],
        ];
    }

    public function onKernelException(ExceptionEvent $event): void
    {
        $exception = $event->getThrowable();
        $request = $event->getRequest();

        // Only handle API routes as JSON
        if (!str_starts_with($request->getPathInfo(), '/api/')) {
            return;
        }

        [$statusCode, $errorCode, $message] = $this->mapException($exception);

        $response = new JsonResponse(
            ['error' => $message, 'code' => $errorCode],
            $statusCode
        );

        $event->setResponse($response);
    }

    private function mapException(\Throwable $exception): array
    {
        $message = $exception->getMessage();

        if ($exception instanceof \InvalidArgumentException) {
            return [400, 'VALIDATION_ERROR', $message];
        }

        if ($exception instanceof \RuntimeException) {
            if (str_contains($message, 'NOT_FOUND')) {
                $clean = preg_replace('/^NOT_FOUND:\s*/', '', $message);
                return [404, 'NOT_FOUND', $clean];
            }
            if (str_contains($message, 'UNAUTHORIZED')) {
                $clean = preg_replace('/^UNAUTHORIZED:\s*/', '', $message);
                return [401, 'UNAUTHORIZED', $clean];
            }
            if (str_contains($message, 'FORBIDDEN')) {
                $clean = preg_replace('/^FORBIDDEN:\s*/', '', $message);
                return [403, 'FORBIDDEN', $clean];
            }
            if (str_contains($message, 'CONFLICT')) {
                $clean = preg_replace('/^CONFLICT:\s*/', '', $message);
                return [409, 'CONFLICT', $clean];
            }
        }

        return [500, 'SERVER_ERROR', 'An unexpected error occurred'];
    }
}
