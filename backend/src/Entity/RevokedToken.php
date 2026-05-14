<?php

declare(strict_types=1);

namespace App\Entity;

use App\Repository\RevokedTokenRepository;
use Doctrine\ORM\Mapping as ORM;

#[ORM\Entity(repositoryClass: RevokedTokenRepository::class)]
#[ORM\Table(name: 'revoked_tokens')]
class RevokedToken
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column(type: 'bigint')]
    private ?int $id = null;

    #[ORM\Column(type: 'string', length: 64, unique: true)]
    private string $tokenJti;

    #[ORM\Column(type: 'datetime')]
    private \DateTimeInterface $expiresAt;

    #[ORM\Column(type: 'datetime')]
    private \DateTimeInterface $createdAt;

    public function __construct()
    {
        $this->createdAt = new \DateTime();
    }

    public function getId(): ?int
    {
        return $this->id !== null ? (int) $this->id : null;
    }

    public function getTokenJti(): string
    {
        return $this->tokenJti;
    }

    public function setTokenJti(string $tokenJti): static
    {
        $this->tokenJti = $tokenJti;
        return $this;
    }

    public function getExpiresAt(): \DateTimeInterface
    {
        return $this->expiresAt;
    }

    public function setExpiresAt(\DateTimeInterface $expiresAt): static
    {
        $this->expiresAt = $expiresAt;
        return $this;
    }

    public function getCreatedAt(): \DateTimeInterface
    {
        return $this->createdAt;
    }

    public function setCreatedAt(\DateTimeInterface $createdAt): static
    {
        $this->createdAt = $createdAt;
        return $this;
    }
}
