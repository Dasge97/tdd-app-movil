<?php

declare(strict_types=1);

namespace App\Service;

use App\Entity\User;
use App\Entity\UserNotification;
use App\Repository\UserNotificationRepository;

class NotificationService
{
    public function __construct(
        private readonly UserNotificationRepository $notificationRepository
    ) {
    }

    public function getNotifications(User $user, bool $unreadOnly = false): array
    {
        return $this->notificationRepository->findByUser($user->getId(), $unreadOnly, 50);
    }

    public function markRead(User $user, int $notificationId): void
    {
        $notification = $this->notificationRepository->find($notificationId);

        if ($notification === null) {
            throw new \RuntimeException('NOT_FOUND: notification not found');
        }

        if ($notification->getUser()->getId() !== $user->getId()) {
            throw new \RuntimeException('FORBIDDEN: not your notification');
        }

        $notification->setIsRead(true);
        $notification->setReadAt(new \DateTime());
        $this->notificationRepository->save($notification);
    }

    public function markAllRead(User $user): void
    {
        $this->notificationRepository->markAllRead($user->getId());
    }

    public function create(
        User $user,
        string $type,
        string $title,
        string $body,
        ?array $data = null
    ): UserNotification {
        $notification = new UserNotification();
        $notification->setUser($user);
        $notification->setType($type);
        $notification->setTitle($title);
        $notification->setBody($body);
        $notification->setData($data);

        $this->notificationRepository->save($notification);

        return $notification;
    }
}
