<?php

declare(strict_types=1);

namespace App\Controller\Api;

use App\Entity\Friend;
use App\Entity\User;
use App\Repository\UserRepository;
use App\Service\SocialService;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\Routing\Attribute\Route;

#[Route('/api/v1')]
class SocialController extends AbstractController
{
    public function __construct(
        private readonly SocialService $socialService,
        private readonly UserRepository $userRepository
    ) {
    }

    #[Route('/friends', name: 'api_friends_list', methods: ['GET'])]
    public function getFriends(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->attributes->get('currentUser');
        $friends = $this->socialService->getFriends($user);
        $pending = $this->socialService->getPendingRequests($user);

        return new JsonResponse([
            'friends' => array_map(fn(Friend $f) => $this->normalizeFriend($f), $friends),
            'pending' => array_map(fn(Friend $f) => $this->normalizeFriend($f), $pending),
        ]);
    }

    #[Route('/friends/{userId}', name: 'api_friends_request', methods: ['POST'], requirements: ['userId' => '\d+'])]
    public function sendRequest(int $userId, Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->attributes->get('currentUser');
        $friend = $this->socialService->sendFriendRequest($user, $userId);

        return new JsonResponse($this->normalizeFriend($friend), 201);
    }

    #[Route('/friends', name: 'api_friends_request_by_username', methods: ['POST'])]
    public function sendRequestByUsername(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->attributes->get('currentUser');
        $data = json_decode($request->getContent(), true) ?? [];
        $username = trim((string) ($data['username'] ?? ''));

        if ($username === '') {
            throw new \InvalidArgumentException('username is required');
        }

        $target = $this->userRepository->findByUsername($username);
        if ($target === null) {
            throw new \RuntimeException('NOT_FOUND: user not found');
        }

        $friend = $this->socialService->sendFriendRequest($user, $target->getId());

        return new JsonResponse($this->normalizeFriend($friend), 201);
    }

    #[Route('/friends/{userId}/accept', name: 'api_friends_accept', methods: ['PUT'], requirements: ['userId' => '\d+'])]
    public function acceptRequest(int $userId, Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->attributes->get('currentUser');
        $friend = $this->socialService->acceptFriendRequest($user, $userId);

        return new JsonResponse($this->normalizeFriend($friend));
    }

    #[Route('/friends/{userId}', name: 'api_friends_remove', methods: ['DELETE'], requirements: ['userId' => '\d+'])]
    public function removeFriend(int $userId, Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->attributes->get('currentUser');
        $this->socialService->removeFriend($user, $userId);

        return new JsonResponse(['success' => true]);
    }

    #[Route('/favorites/{debateId}', name: 'api_favorites_toggle_add', methods: ['POST'], requirements: ['debateId' => '\d+'])]
    public function addFavorite(int $debateId, Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->attributes->get('currentUser');
        $added = $this->socialService->toggleFavorite($user, $debateId);

        return new JsonResponse(['favorited' => $added], $added ? 201 : 200);
    }

    #[Route('/favorites/{debateId}', name: 'api_favorites_remove', methods: ['DELETE'], requirements: ['debateId' => '\d+'])]
    public function removeFavorite(int $debateId, Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->attributes->get('currentUser');
        $this->socialService->toggleFavorite($user, $debateId);

        return new JsonResponse(['success' => true]);
    }

    private function normalizeFriend(Friend $friend): array
    {
        return [
            'id'          => $friend->getId(),
            'status'      => $friend->getStatus(),
            'createdAt'   => $friend->getCreatedAt()->format(\DateTimeInterface::ATOM),
            'respondedAt' => $friend->getRespondedAt()?->format(\DateTimeInterface::ATOM),
            'requester'   => [
                'id'       => $friend->getRequester()->getId(),
                'username' => $friend->getRequester()->getUsername(),
                'avatarUrl' => $friend->getRequester()->getAvatarUrl(),
            ],
            'addressee'   => [
                'id'       => $friend->getAddressee()->getId(),
                'username' => $friend->getAddressee()->getUsername(),
                'avatarUrl' => $friend->getAddressee()->getAvatarUrl(),
            ],
        ];
    }
}
