<?php

declare(strict_types=1);

namespace App\Entity;

use Doctrine\ORM\Mapping as ORM;

#[ORM\Entity]
#[ORM\Table(name: 'user_report')]
class UserReport
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column]
    private ?int $id = null;

    #[ORM\ManyToOne(targetEntity: User::class)]
    #[ORM\JoinColumn(nullable: false)]
    private User $reportedBy;

    #[ORM\Column(length: 20)]
    private string $entityType;

    #[ORM\Column]
    private int $entityId;

    #[ORM\Column(length: 255, nullable: true)]
    private ?string $reason;

    #[ORM\Column]
    private \DateTimeImmutable $createdAt;

    public function __construct(
        User $reportedBy,
        string $entityType,
        int $entityId,
        ?string $reason,
    ) {
        $this->reportedBy = $reportedBy;
        $this->entityType = $entityType;
        $this->entityId   = $entityId;
        $this->reason     = $reason;
        $this->createdAt  = new \DateTimeImmutable();
    }

    public function getId(): ?int                    { return $this->id; }
    public function getReportedBy(): User            { return $this->reportedBy; }
    public function getEntityType(): string          { return $this->entityType; }
    public function getEntityId(): int               { return $this->entityId; }
    public function getReason(): ?string             { return $this->reason; }
    public function getCreatedAt(): \DateTimeImmutable { return $this->createdAt; }
}
