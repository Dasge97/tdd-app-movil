<?php

declare(strict_types=1);

namespace App\Entity;

use App\Repository\ChatParticipantRepository;
use Doctrine\ORM\Mapping as ORM;

#[ORM\Entity(repositoryClass: ChatParticipantRepository::class)]
#[ORM\Table(name: 'chat_participants')]
class ChatParticipant
{
    #[ORM\Id]
    #[ORM\ManyToOne(targetEntity: ChatConversation::class, inversedBy: 'participants')]
    #[ORM\JoinColumn(nullable: false, onDelete: 'CASCADE')]
    private ChatConversation $conversation;

    #[ORM\Id]
    #[ORM\ManyToOne(targetEntity: User::class)]
    #[ORM\JoinColumn(nullable: false, onDelete: 'CASCADE')]
    private User $user;

    #[ORM\Column(type: 'bigint', nullable: true)]
    private ?int $lastReadMsgId = null;

    #[ORM\Column(type: 'datetime', nullable: true)]
    private ?\DateTimeInterface $lastReadAt = null;

    public function getConversation(): ChatConversation
    {
        return $this->conversation;
    }

    public function setConversation(ChatConversation $conversation): static
    {
        $this->conversation = $conversation;
        return $this;
    }

    public function getUser(): User
    {
        return $this->user;
    }

    public function setUser(User $user): static
    {
        $this->user = $user;
        return $this;
    }

    public function getLastReadMsgId(): ?int
    {
        return $this->lastReadMsgId;
    }

    public function setLastReadMsgId(?int $lastReadMsgId): static
    {
        $this->lastReadMsgId = $lastReadMsgId;
        return $this;
    }

    public function getLastReadAt(): ?\DateTimeInterface
    {
        return $this->lastReadAt;
    }

    public function setLastReadAt(?\DateTimeInterface $lastReadAt): static
    {
        $this->lastReadAt = $lastReadAt;
        return $this;
    }
}
