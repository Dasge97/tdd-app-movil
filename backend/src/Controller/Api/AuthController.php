<?php

declare(strict_types=1);

namespace App\Controller\Api;

use App\Service\AuthService;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\Routing\Attribute\Route;

#[Route('/api/v1/auth')]
class AuthController extends AbstractController
{
    public function __construct(
        private readonly AuthService $authService
    ) {
    }

    #[Route('/register', name: 'api_auth_register', methods: ['POST'])]
    public function register(Request $request): JsonResponse
    {
        $data = json_decode($request->getContent(), true) ?? [];

        $result = $this->authService->register(
            $data['username'] ?? '',
            $data['email'] ?? '',
            $data['password'] ?? ''
        );

        return new JsonResponse($result, 201);
    }

    #[Route('/login', name: 'api_auth_login', methods: ['POST'])]
    public function login(Request $request): JsonResponse
    {
        $data = json_decode($request->getContent(), true) ?? [];

        $result = $this->authService->login(
            $data['email'] ?? '',
            $data['password'] ?? ''
        );

        return new JsonResponse($result);
    }

    #[Route('/refresh', name: 'api_auth_refresh', methods: ['POST'])]
    public function refresh(Request $request): JsonResponse
    {
        $authHeader = $request->headers->get('Authorization', '');
        $token = str_starts_with($authHeader, 'Bearer ') ? substr($authHeader, 7) : '';

        if (empty($token)) {
            $data = json_decode($request->getContent(), true) ?? [];
            $token = $data['refreshToken'] ?? '';
        }

        $result = $this->authService->refresh($token);

        return new JsonResponse($result);
    }

    #[Route('/logout', name: 'api_auth_logout', methods: ['POST'])]
    public function logout(Request $request): JsonResponse
    {
        $authHeader = $request->headers->get('Authorization', '');
        $accessToken = str_starts_with($authHeader, 'Bearer ') ? substr($authHeader, 7) : '';

        if (!empty($accessToken)) {
            $this->authService->logout($accessToken);
        }

        // Also revoke the refresh token if provided, so a stolen refresh token
        // cannot be used to mint new access tokens after logout.
        $data = json_decode($request->getContent(), true) ?? [];
        $refreshToken = $data['refreshToken'] ?? '';
        if (!empty($refreshToken)) {
            $this->authService->logout($refreshToken);
        }

        return new JsonResponse(['message' => 'logged out']);
    }
}
