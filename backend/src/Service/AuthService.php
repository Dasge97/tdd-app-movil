<?php

declare(strict_types=1);

namespace App\Service;

use App\Entity\RevokedToken;
use App\Entity\User;
use App\Repository\RevokedTokenRepository;
use App\Repository\UserRepository;
use App\Serializer\UserNormalizer;

class AuthService
{
    public function __construct(
        private readonly UserRepository $userRepository,
        private readonly RevokedTokenRepository $revokedTokenRepository,
        private readonly JwtService $jwtService,
        private readonly UserNormalizer $userNormalizer
    ) {
    }

    public function register(string $username, string $email, string $password): array
    {
        if (empty($username) || empty($email) || empty($password)) {
            throw new \InvalidArgumentException('username, email and password are required');
        }

        if ($this->userRepository->findByEmail($email) !== null) {
            throw new \RuntimeException('CONFLICT: email already in use');
        }

        if ($this->userRepository->findByUsername($username) !== null) {
            throw new \RuntimeException('CONFLICT: username already in use');
        }

        $user = new User();
        $user->setUsername($username);
        $user->setEmail($email);
        $user->setPasswordHash(password_hash($password, PASSWORD_BCRYPT));
        $user->setRole('user');
        $user->setStatus('active');

        $this->userRepository->save($user);

        return [
            'accessToken'  => $this->jwtService->createAccessToken($user),
            'refreshToken' => $this->jwtService->createRefreshToken($user),
            'user'         => $this->userNormalizer->normalize($user),
        ];
    }

    public function login(string $email, string $password): array
    {
        $user = $this->userRepository->findByEmail($email);

        if ($user === null || !password_verify($password, $user->getPasswordHash())) {
            throw new \RuntimeException('UNAUTHORIZED: invalid credentials');
        }

        if ($user->getStatus() === 'suspended') {
            throw new \RuntimeException('FORBIDDEN: account suspended');
        }

        return [
            'accessToken'  => $this->jwtService->createAccessToken($user),
            'refreshToken' => $this->jwtService->createRefreshToken($user),
            'user'         => $this->userNormalizer->normalize($user),
        ];
    }

    public function refresh(string $refreshToken): array
    {
        try {
            $payload = $this->jwtService->decode($refreshToken);
        } catch (\Exception $e) {
            throw new \RuntimeException('UNAUTHORIZED: invalid refresh token');
        }

        if (($payload['type'] ?? '') !== 'refresh') {
            throw new \RuntimeException('UNAUTHORIZED: not a refresh token');
        }

        $jti = $payload['jti'] ?? '';
        if ($this->jwtService->isRevoked($jti)) {
            throw new \RuntimeException('UNAUTHORIZED: token revoked');
        }

        $userId = (int) ($payload['sub'] ?? 0);
        $user = $this->userRepository->find($userId);

        if ($user === null) {
            throw new \RuntimeException('NOT_FOUND: user not found');
        }

        // Revoke old refresh token
        $revoked = new RevokedToken();
        $revoked->setTokenJti($jti);
        $revoked->setExpiresAt((new \DateTime())->setTimestamp($payload['exp']));
        $this->revokedTokenRepository->save($revoked);

        return [
            'accessToken'  => $this->jwtService->createAccessToken($user),
            'refreshToken' => $this->jwtService->createRefreshToken($user),
            'user'         => $this->userNormalizer->normalize($user),
        ];
    }

    public function logout(string $accessToken): void
    {
        try {
            $payload = $this->jwtService->decode($accessToken);
        } catch (\Exception $e) {
            return; // Already invalid, no need to revoke
        }

        $jti = $payload['jti'] ?? null;
        if ($jti === null) {
            return;
        }

        if (!$this->jwtService->isRevoked($jti)) {
            $revoked = new RevokedToken();
            $revoked->setTokenJti($jti);
            $revoked->setExpiresAt((new \DateTime())->setTimestamp($payload['exp'] ?? time() + 900));
            $this->revokedTokenRepository->save($revoked);
        }
    }
}
