<?php

declare(strict_types=1);

namespace App\Entity;

use App\Repository\ChatConversationRepository;
use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\Common\Collections\Collection;
use Doctrine\ORM\Mapping as ORM;

#[ORM\Entity(repositoryClass: ChatConversationRepository::class)]
#[ORM\Table(name: 'chat_conversations')]
#[ORM\HasLifecycleCallbacks]
class ChatConversation
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column(type: 'bigint')]
    private ?int $id = null;

    #[ORM\Column(type: 'string', length: 64, unique: true)]
    private string $dmKey;

    #[ORM\Column(type: 'datetime')]
    private \DateTimeInterface $createdAt;

    #[ORM\Column(type: 'datetime', nullable: true)]
    private ?\DateTimeInterface $updatedAt = null;

    #[ORM\OneToMany(targetEntity: ChatParticipant::class, mappedBy: 'conversation', cascade: ['persist', 'remove'])]
    private Collection $participants;

    #[ORM\OneToMany(targetEntity: ChatMessage::class, mappedBy: 'conversation', cascade: ['persist', 'remove'])]
    private Collection $messages;

    public function __construct()
    {
        $this->createdAt = new \DateTime();
        $this->participants = new ArrayCollection();
        $this->messages = new ArrayCollection();
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

    public function getDmKey(): string
    {
        return $this->dmKey;
    }

    public function setDmKey(string $dmKey): static
    {
        $this->dmKey = $dmKey;
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

    public function getParticipants(): Collection
    {
        return $this->participants;
    }

    public function getMessages(): Collection
    {
        return $this->messages;
    }
}
