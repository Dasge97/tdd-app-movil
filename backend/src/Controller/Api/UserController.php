<?php

declare(strict_types=1);

namespace App\Controller\Api;

use App\Entity\Debate;
use App\Entity\Favorite;
use App\Entity\User;
use App\Repository\UserRepository;
use App\Serializer\UserNormalizer;
use App\Service\SocialService;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\Routing\Attribute\Route;

#[Route('/api/v1/users')]
class UserController extends AbstractController
{
    public function __construct(
        private readonly UserRepository $userRepository,
        private readonly UserNormalizer $userNormalizer,
        private readonly SocialService $socialService
    ) {
    }

    #[Route('/me', name: 'api_users_me', methods: ['GET'])]
    public function me(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->attributes->get('currentUser');
        return new JsonResponse($this->userNormalizer->normalize($user));
    }

    #[Route('/{username}', name: 'api_users_show', methods: ['GET'])]
    public function show(string $username): JsonResponse
    {
        $user = $this->userRepository->findByUsername($username);

        if ($user === null) {
            throw new \RuntimeException('NOT_FOUND: user not found');
        }

        return new JsonResponse($this->userNormalizer->normalize($user));
    }

    #[Route('/me', name: 'api_users_me_update', methods: ['PUT'])]
    public function updateMe(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->attributes->get('currentUser');
        $data = json_decode($request->getContent(), true) ?? [];

        if (array_key_exists('bio', $data)) {
            $user->setBio($data['bio']);
        }
        if (array_key_exists('location', $data)) {
            $user->setLocation($data['location']);
        }
        if (array_key_exists('avatarUrl', $data)) {
            $user->setAvatarUrl($data['avatarUrl']);
        }
        if (array_key_exists('profileTagline', $data)) {
            $user->setProfileTagline($data['profileTagline']);
        }

        $this->userRepository->save($user);

        return new JsonResponse($this->userNormalizer->normalize($user));
    }

    #[Route('/me/favorites', name: 'api_users_me_favorites', methods: ['GET'])]
    public function getFavorites(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->attributes->get('currentUser');
        $page = max(1, (int) $request->query->get('page', '1'));

        $favorites = $this->socialService->getFavorites($user, $page);

        $data = array_map(fn(Favorite $f) => [
            'id'        => $f->getId(),
            'createdAt' => $f->getCreatedAt()->format(\DateTimeInterface::ATOM),
            'debate'    => [
                'id'      => $f->getDebate()->getId(),
                'title'   => $f->getDebate()->getTitle(),
                'dayDate' => $f->getDebate()->getDayDate()->format('Y-m-d'),
            ],
        ], $favorites);

        return new JsonResponse($data);
    }
}
