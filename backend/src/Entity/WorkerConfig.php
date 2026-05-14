<?php

declare(strict_types=1);

namespace App\Entity;

use App\Repository\WorkerConfigRepository;
use Doctrine\ORM\Mapping as ORM;

#[ORM\Entity(repositoryClass: WorkerConfigRepository::class)]
#[ORM\Table(name: 'worker_config')]
class WorkerConfig
{
    #[ORM\Id]
    #[ORM\Column(type: 'integer', options: ['default' => 1])]
    private int $id = 1;

    #[ORM\Column(type: 'string', length: 100, options: ['default' => '0 7 * * *'])]
    private string $schedule = '0 7 * * *';

    #[ORM\Column(type: 'boolean', options: ['default' => true])]
    private bool $enabled = true;

    #[ORM\Column(type: 'boolean', options: ['default' => false])]
    private bool $triggerPending = false;

    #[ORM\Column(type: 'integer', options: ['default' => 14])]
    private int $dedupDays = 14;

    #[ORM\Column(type: 'integer', options: ['default' => 3])]
    private int $rotationLimitDays = 3;

    #[ORM\Column(type: 'integer', options: ['default' => 5])]
    private int $targetDebates = 5;

    #[ORM\Column(type: 'json', nullable: true)]
    private ?array $rules = null;

    #[ORM\Column(type: 'string', length: 180, nullable: true)]
    private ?string $opencodeModel = null;

    #[ORM\Column(type: 'string', length: 80, nullable: true)]
    private ?string $opencodeProvider = null;

    #[ORM\Column(type: 'datetime', nullable: true)]
    private ?\DateTimeInterface $updatedAt = null;

    public function getId(): int
    {
        return $this->id;
    }

    public function setId(int $id): static
    {
        $this->id = $id;
        return $this;
    }

    public function getSchedule(): string
    {
        return $this->schedule;
    }

    public function setSchedule(string $schedule): static
    {
        $this->schedule = $schedule;
        return $this;
    }

    public function isEnabled(): bool
    {
        return $this->enabled;
    }

    public function setEnabled(bool $enabled): static
    {
        $this->enabled = $enabled;
        return $this;
    }

    public function isTriggerPending(): bool
    {
        return $this->triggerPending;
    }

    public function setTriggerPending(bool $triggerPending): static
    {
        $this->triggerPending = $triggerPending;
        return $this;
    }

    public function getDedupDays(): int
    {
        return $this->dedupDays;
    }

    public function setDedupDays(int $dedupDays): static
    {
        $this->dedupDays = $dedupDays;
        return $this;
    }

    public function getRotationLimitDays(): int
    {
        return $this->rotationLimitDays;
    }

    public function setRotationLimitDays(int $rotationLimitDays): static
    {
        $this->rotationLimitDays = $rotationLimitDays;
        return $this;
    }

    public function getTargetDebates(): int
    {
        return $this->targetDebates;
    }

    public function setTargetDebates(int $targetDebates): static
    {
        $this->targetDebates = $targetDebates;
        return $this;
    }

    public function getRules(): ?array
    {
        return $this->rules;
    }

    public function setRules(?array $rules): static
    {
        $this->rules = $rules;
        return $this;
    }

    public function getOpencodeModel(): ?string
    {
        return $this->opencodeModel;
    }

    public function setOpencodeModel(?string $opencodeModel): static
    {
        $this->opencodeModel = $opencodeModel;
        return $this;
    }

    public function getOpencodeProvider(): ?string
    {
        return $this->opencodeProvider;
    }

    public function setOpencodeProvider(?string $opencodeProvider): static
    {
        $this->opencodeProvider = $opencodeProvider;
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
}
