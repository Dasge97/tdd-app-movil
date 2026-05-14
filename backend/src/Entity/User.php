<?php

declare(strict_types=1);

namespace App\Entity;

use App\Repository\UserRepository;
use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\Common\Collections\Collection;
use Doctrine\ORM\Mapping as ORM;

#[ORM\Entity(repositoryClass: UserRepository::class)]
#[ORM\Table(name: 'users')]
#[ORM\HasLifecycleCallbacks]
class User
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column(type: 'bigint')]
    private ?int $id = null;

    #[ORM\Column(type: 'string', length: 50, unique: true)]
    private string $username;

    #[ORM\Column(type: 'string', length: 255, unique: true)]
    private string $email;

    #[ORM\Column(type: 'string', length: 255)]
    private string $passwordHash;

    #[ORM\Column(type: 'string', length: 280, nullable: true)]
    private ?string $bio = null;

    #[ORM\Column(type: 'string', length: 255, nullable: true)]
    private ?string $avatarUrl = null;

    #[ORM\Column(type: 'string', length: 120, nullable: true)]
    private ?string $location = null;

    #[ORM\Column(type: 'string', length: 160, nullable: true)]
    private ?string $profileTagline = null;

    #[ORM\Column(type: 'json', nullable: true)]
    private ?array $profileTraits = null;

    #[ORM\Column(type: 'integer', options: ['default' => 0])]
    private int $reliabilityScore = 0;

    #[ORM\Column(type: 'string', length: 20, options: ['default' => 'user'])]
    private string $role = 'user';

    #[ORM\Column(type: 'string', length: 20, options: ['default' => 'active'])]
    private string $status = 'active';

    #[ORM\Column(type: 'boolean', options: ['default' => false])]
    private bool $isAiPersona = false;

    #[ORM\Column(type: 'boolean', options: ['default' => false])]
    private bool $isShadowBanned = false;

    #[ORM\Column(type: 'string', length: 80, nullable: true)]
    private ?string $personaSpecialty = null;

    #[ORM\Column(type: 'datetime')]
    private \DateTimeInterface $createdAt;

    #[ORM\Column(type: 'datetime', nullable: true)]
    private ?\DateTimeInterface $updatedAt = null;

    #[ORM\OneToMany(targetEntity: Debate::class, mappedBy: 'createdBy')]
    private Collection $debates;

    #[ORM\OneToMany(targetEntity: Comment::class, mappedBy: 'user')]
    private Collection $comments;

    public function __construct()
    {
        $this->debates = new ArrayCollection();
        $this->comments = new ArrayCollection();
        $this->createdAt = new \DateTime();
    }

    #[ORM\PreUpdate]
    public function onPreUpdate(): void
    {
        $this->updatedAt = new \DateTime();
    }

    public function getId(): ?int
    {
        return $this->id !== null ? (int) $this->id : null;
    }

    public function getUsername(): string
    {
        return $this->username;
    }

    public function setUsername(string $username): static
    {
        $this->username = $username;
        return $this;
    }

    public function getEmail(): string
    {
        return $this->email;
    }

    public function setEmail(string $email): static
    {
        $this->email = $email;
        return $this;
    }

    public function getPasswordHash(): string
    {
        return $this->passwordHash;
    }

    public function setPasswordHash(string $passwordHash): static
    {
        $this->passwordHash = $passwordHash;
        return $this;
    }

    public function getBio(): ?string
    {
        return $this->bio;
    }

    public function setBio(?string $bio): static
    {
        $this->bio = $bio;
        return $this;
    }

    public function getAvatarUrl(): ?string
    {
        return $this->avatarUrl;
    }

    public function setAvatarUrl(?string $avatarUrl): static
    {
        $this->avatarUrl = $avatarUrl;
        return $this;
    }

    public function getLocation(): ?string
    {
        return $this->location;
    }

    public function setLocation(?string $location): static
    {
        $this->location = $location;
        return $this;
    }

    public function getProfileTagline(): ?string
    {
        return $this->profileTagline;
    }

    public function setProfileTagline(?string $profileTagline): static
    {
        $this->profileTagline = $profileTagline;
        return $this;
    }

    public function getProfileTraits(): ?array
    {
        return $this->profileTraits;
    }

    public function setProfileTraits(?array $profileTraits): static
    {
        $this->profileTraits = $profileTraits;
        return $this;
    }

    public function getReliabilityScore(): int
    {
        return $this->reliabilityScore;
    }

    public function setReliabilityScore(int $reliabilityScore): static
    {
        $this->reliabilityScore = $reliabilityScore;
        return $this;
    }

    public function getRole(): string
    {
        return $this->role;
    }

    public function setRole(string $role): static
    {
        $this->role = $role;
        return $this;
    }

    public function getStatus(): string
    {
        return $this->status;
    }

    public function setStatus(string $status): static
    {
        $this->status = $status;
        return $this;
    }

    public function isAiPersona(): bool
    {
        return $this->isAiPersona;
    }

    public function setIsAiPersona(bool $isAiPersona): static
    {
        $this->isAiPersona = $isAiPersona;
        return $this;
    }

    public function isShadowBanned(): bool
    {
        return $this->isShadowBanned;
    }

    public function setIsShadowBanned(bool $isShadowBanned): static
    {
        $this->isShadowBanned = $isShadowBanned;
        return $this;
    }

    public function getPersonaSpecialty(): ?string
    {
        return $this->personaSpecialty;
    }

    public function setPersonaSpecialty(?string $personaSpecialty): static
    {
        $this->personaSpecialty = $personaSpecialty;
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

    public function getUpdatedAt(): ?\DateTimeInterface
    {
        return $this->updatedAt;
    }

    public function setUpdatedAt(?\DateTimeInterface $updatedAt): static
    {
        $this->updatedAt = $updatedAt;
        return $this;
    }

    public function getDebates(): Collection
    {
        return $this->debates;
    }

    public function getComments(): Collection
    {
        return $this->comments;
    }
}
