<?php

declare(strict_types=1);

namespace App\Service;

use App\Entity\Favorite;
use App\Entity\Friend;
use App\Entity\User;
use App\Repository\DebateRepository;
use App\Repository\FavoriteRepository;
use App\Repository\FriendRepository;
use App\Repository\UserRepository;

class SocialService
{
    private const PAGE_SIZE = 20;

    public function __construct(
        private readonly FriendRepository $friendRepository,
        private readonly FavoriteRepository $favoriteRepository,
        private readonly UserRepository $userRepository,
        private readonly DebateRepository $debateRepository
    ) {
    }

    public function getFriends(User $user): array
    {
        return $this->friendRepository->findFriends($user->getId());
    }

    public function getPendingRequests(User $user): array
    {
        return $this->friendRepository->findPending($user->getId());
    }

    public function sendFriendRequest(User $requester, int $addresseeId): Friend
    {
        if ($requester->getId() === $addresseeId) {
            throw new \InvalidArgumentException('Cannot send friend request to yourself');
        }

        $addressee = $this->userRepository->find($addresseeId);
        if ($addressee === null) {
            throw new \RuntimeException('NOT_FOUND: user not found');
        }

        $existing = $this->friendRepository->findRelation($requester->getId(), $addresseeId);
        if ($existing !== null) {
            throw new \RuntimeException('CONFLICT: relationship already exists');
        }

        $friend = new Friend();
        $friend->setRequester($requester);
        $friend->setAddressee($addressee);
        $friend->setStatus('pending');

        $this->friendRepository->save($friend);

        return $friend;
    }

    public function acceptFriendRequest(User $user, int $requesterUserId): Friend
    {
        $relation = $this->friendRepository->findRelation($requesterUserId, $user->getId());

        if ($relation === null) {
            throw new \RuntimeException('NOT_FOUND: friend request not found');
        }

        if ($relation->getAddressee()->getId() !== $user->getId()) {
            throw new \RuntimeException('FORBIDDEN: not your request to accept');
        }

        if ($relation->getStatus() !== 'pending') {
            throw new \InvalidArgumentException('Request is not pending');
        }

        $relation->setStatus('accepted');
        $relation->setRespondedAt(new \DateTime());
        $this->friendRepository->save($relation);

        return $relation;
    }

    public function rejectFriendRequest(User $user, int $requesterUserId): Friend
    {
        $relation = $this->friendRepository->findRelation($requesterUserId, $user->getId());

        if ($relation === null) {
            throw new \RuntimeException('NOT_FOUND: friend request not found');
        }

        if ($relation->getAddressee()->getId() !== $user->getId()) {
            throw new \RuntimeException('FORBIDDEN: not your request to reject');
        }

        $relation->setStatus('rejected');
        $relation->setRespondedAt(new \DateTime());
        $this->friendRepository->save($relation);

        return $relation;
    }

    public function removeFriend(User $user, int $friendId): void
    {
        $relation = $this->friendRepository->findRelation($user->getId(), $friendId);

        if ($relation === null) {
            throw new \RuntimeException('NOT_FOUND: friendship not found');
        }

        $em = $this->friendRepository->getEntityManager();
        $em->remove($relation);
        $em->flush();
    }

    public function toggleFavorite(User $user, int $debateId): bool
    {
        $debate = $this->debateRepository->find($debateId);
        if ($debate === null) {
            throw new \RuntimeException('NOT_FOUND: debate not found');
        }

        $existing = $this->favoriteRepository->findByUserAndDebate($user->getId(), $debateId);

        if ($existing !== null) {
            $this->favoriteRepository->delete($user->getId(), $debateId);
            return false;
        }

        $this->favoriteRepository->upsert($user->getId(), $debateId);
        return true;
    }

    public function getFavorites(User $user, int $page): array
    {
        $offset = ($page - 1) * self::PAGE_SIZE;
        return $this->favoriteRepository->findByUser($user->getId(), self::PAGE_SIZE, $offset);
    }
}
