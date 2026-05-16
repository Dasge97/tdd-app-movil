<?php

declare(strict_types=1);

namespace App\Controller\Api;

use App\Entity\Favorite;
use App\Entity\User;
use App\Repository\UserRepository;
use App\Serializer\UserNormalizer;
use App\Service\SocialService;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\HttpFoundation\File\UploadedFile;

#[Route('/api/v1/users')]
class UserController extends AbstractController
{
    public function __construct(
        private readonly UserRepository $userRepository,
        private readonly UserNormalizer $userNormalizer,
        private readonly SocialService $socialService
    ) {
    }

    /** Top usuarios reales por reliabilityScore — para el tab Protagonistas. */
    #[Route('/protagonistas', name: 'api_users_protagonistas', methods: ['GET'])]
    public function protagonistas(Request $request): JsonResponse
    {
        $limit = min(50, max(1, (int) $request->query->get('limit', '20')));
        $users = $this->userRepository->findProtagonistaRanking($limit);

        $data = array_map(fn(User $u) => [
            'id'               => $u->getId(),
            'username'         => $u->getUsername(),
            'avatarUrl'        => $u->getAvatarUrl(),
            'bio'              => $u->getBio(),
            'profileTagline'   => $u->getProfileTagline(),
            'reliabilityScore' => $u->getReliabilityScore(),
        ], $users);

        return new JsonResponse($data);
    }

    #[Route('/me', name: 'api_users_me', methods: ['GET'])]
    public function me(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->attributes->get('currentUser');
        return new JsonResponse($this->userNormalizer->normalize($user, includePrivate: true));
    }

    #[Route('/{username}', name: 'api_users_show', methods: ['GET'])]
    public function show(string $username, Request $request): JsonResponse
    {
        $user = $this->userRepository->findByUsername($username);

        if ($user === null) {
            throw new \RuntimeException('NOT_FOUND: user not found');
        }

        /** @var User|null $current */
        $current = $request->attributes->get('currentUser');
        $isSelf = $current !== null && $current->getId() === $user->getId();

        return new JsonResponse($this->userNormalizer->normalize($user, includePrivate: $isSelf));
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

        return new JsonResponse($this->userNormalizer->normalize($user, includePrivate: true));
    }

    #[Route('/me/avatar', name: 'api_users_me_avatar', methods: ['POST'])]
    public function uploadAvatar(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->attributes->get('currentUser');

        /** @var UploadedFile|null $file */
        $file = $request->files->get('avatar');

        if ($file === null) {
            return new JsonResponse(['error' => 'No se recibió ningún archivo'], 400);
        }

        $allowed = ['image/jpeg', 'image/png', 'image/webp'];
        if (!in_array($file->getMimeType(), $allowed, true)) {
            return new JsonResponse(['error' => 'Formato no permitido. Usa JPG, PNG o WebP'], 415);
        }

        if ($file->getSize() > 5 * 1024 * 1024) {
            return new JsonResponse(['error' => 'El archivo supera los 5 MB'], 413);
        }

        $uploadDir = $this->getParameter('kernel.project_dir') . '/public/uploads/avatars';
        if (!is_dir($uploadDir)) {
            mkdir($uploadDir, 0755, true);
        }

        $ext = match ($file->getMimeType()) {
            'image/jpeg' => 'jpg',
            'image/webp' => 'webp',
            default      => 'png',
        };

        // Remove previous avatar file if it was uploaded (not an external URL)
        $prev = $user->getAvatarUrl();
        if ($prev !== null && str_contains($prev, '/uploads/avatars/')) {
            $prevFile = $this->getParameter('kernel.project_dir') . '/public' . parse_url($prev, PHP_URL_PATH);
            if (file_exists($prevFile)) {
                unlink($prevFile);
            }
        }

        $filename = 'u' . $user->getId() . '.' . $ext;
        $file->move($uploadDir, $filename);

        $avatarUrl = $request->getSchemeAndHttpHost() . '/uploads/avatars/' . $filename;
        $user->setAvatarUrl($avatarUrl);
        $this->userRepository->save($user);

        return new JsonResponse(['avatarUrl' => $avatarUrl]);
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
