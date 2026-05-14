<?php

declare(strict_types=1);

namespace App\Entity;

use App\Repository\IdempotencyKeyRepository;
use Doctrine\ORM\Mapping as ORM;

#[ORM\Entity(repositoryClass: IdempotencyKeyRepository::class)]
#[ORM\Table(name: 'idempotency_keys')]
class IdempotencyKey
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column(type: 'bigint')]
    private ?int $id = null;

    #[ORM\Column(type: 'string', length: 64, unique: true)]
    private string $keyHash;

    #[ORM\Column(type: 'smallint')]
    private int $responseStatus;

    #[ORM\Column(type: 'json')]
    private array $responseBody;

    #[ORM\Column(type: 'datetime')]
    private \DateTimeInterface $createdAt;

    #[ORM\Column(type: 'datetime')]
    private \DateTimeInterface $expiresAt;

    public function __construct()
    {
        $this->createdAt = new \DateTime();
    }

    public function getId(): ?int
    {
        return $this->id !== null ? (int) $this->id : null;
    }

    public function getKeyHash(): string
    {
        return $this->keyHash;
    }

    public function setKeyHash(string $keyHash): static
    {
        $this->keyHash = $keyHash;
        return $this;
    }

    public function getResponseStatus(): int
    {
        return $this->responseStatus;
    }

    public function setResponseStatus(int $responseStatus): static
    {
        $this->responseStatus = $responseStatus;
        return $this;
    }

    public function getResponseBody(): array
    {
        return $this->responseBody;
    }

    public function setResponseBody(array $responseBody): static
    {
        $this->responseBody = $responseBody;
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

    public function getExpiresAt(): \DateTimeInterface
    {
        return $this->expiresAt;
    }

    public function setExpiresAt(\DateTimeInterface $expiresAt): static
    {
        $this->expiresAt = $expiresAt;
        return $this;
    }
}
