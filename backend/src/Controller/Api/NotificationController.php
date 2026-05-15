<?php

declare(strict_types=1);

namespace App\Controller\Api;

use App\Entity\User;
use App\Entity\UserNotification;
use App\Service\NotificationService;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\Routing\Attribute\Route;

#[Route('/api/v1/notifications')]
class NotificationController extends AbstractController
{
    public function __construct(
        private readonly NotificationService $notificationService
    ) {
    }

    #[Route('', name: 'api_notifications_list', methods: ['GET'])]
    public function list(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->attributes->get('currentUser');
        $unreadOnly = filter_var($request->query->get('unreadOnly', 'false'), FILTER_VALIDATE_BOOLEAN);

        $notifications = $this->notificationService->getNotifications($user, $unreadOnly);

        return new JsonResponse(
            array_map(fn(UserNotification $n) => $this->normalize($n), $notifications)
        );
    }

    #[Route('/{id}/read', name: 'api_notifications_read', methods: ['PUT'], requirements: ['id' => '\d+'])]
    public function markRead(int $id, Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->attributes->get('currentUser');
        $this->notificationService->markRead($user, $id);

        return new JsonResponse(['success' => true]);
    }

    #[Route('/read-all', name: 'api_notifications_read_all', methods: ['PUT'])]
    public function markAllRead(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->attributes->get('currentUser');
        $this->notificationService->markAllRead($user);

        return new JsonResponse(['success' => true]);
    }

    private function normalize(UserNotification $n): array
    {
        return [
            'id'        => $n->getId(),
            'userId'    => $n->getUser()->getId(),
            'type'      => $n->getType(),
            'title'     => $n->getTitle(),
            'body'      => $n->getBody(),
            'data'      => $n->getData(),
            'isRead'    => $n->isRead(),
            'createdAt' => $n->getCreatedAt()->format(\DateTimeInterface::ATOM),
            'readAt'    => $n->getReadAt()?->format(\DateTimeInterface::ATOM),
        ];
    }
}
