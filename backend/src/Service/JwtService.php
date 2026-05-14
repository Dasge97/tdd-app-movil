<?php

declare(strict_types=1);

namespace App\Service;

use App\Entity\User;
use App\Repository\RevokedTokenRepository;
use Firebase\JWT\JWT;
use Firebase\JWT\Key;
use Ramsey\Uuid\Uuid;

class JwtService
{
    private string $secret;

    public function __construct(
        string $jwtSecret,
        private readonly RevokedTokenRepository $revokedTokenRepository
    ) {
        $this->secret = $jwtSecret;
    }

    public function createAccessToken(User $user): string
    {
        $now = time();
        $payload = [
            'sub'  => $user->getId(),
            'role' => $user->getRole(),
            'jti'  => Uuid::uuid4()->toString(),
            'iat'  => $now,
            'exp'  => $now + 900, // 15 minutes
            'type' => 'access',
        ];

        return JWT::encode($payload, $this->secret, 'HS256');
    }

    public function createRefreshToken(User $user): string
    {
        $now = time();
        $payload = [
            'sub'  => $user->getId(),
            'type' => 'refresh',
            'jti'  => Uuid::uuid4()->toString(),
            'iat'  => $now,
            'exp'  => $now + 2592000, // 30 days
        ];

        return JWT::encode($payload, $this->secret, 'HS256');
    }

    public function decode(string $token): array
    {
        $decoded = JWT::decode($token, new Key($this->secret, 'HS256'));
        return (array) $decoded;
    }

    public function isRevoked(string $jti): bool
    {
        return $this->revokedTokenRepository->isRevoked($jti);
    }
}
