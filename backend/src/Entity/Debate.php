<?php

declare(strict_types=1);

namespace App\Entity;

use App\Repository\DebateRepository;
use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\Common\Collections\Collection;
use Doctrine\ORM\Mapping as ORM;

#[ORM\Entity(repositoryClass: DebateRepository::class)]
#[ORM\Table(name: 'debates')]
class Debate
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column(type: 'bigint')]
    private ?int $id = null;

    #[ORM\Column(type: 'string', length: 255)]
    private string $title;

    #[ORM\Column(type: 'string', length: 255, nullable: true)]
    private ?string $question = null;

    #[ORM\Column(type: 'text', nullable: true)]
    private ?string $cardSummary = null;

    #[ORM\Column(type: 'text')]
    private string $context;

    #[ORM\Column(type: 'string', length: 255, nullable: true)]
    private ?string $sourceName = null;

    #[ORM\Column(type: 'string', length: 1024, nullable: true)]
    private ?string $sourceUrl = null;

    #[ORM\Column(type: 'datetime', nullable: true)]
    private ?\DateTimeInterface $publishedAt = null;

    #[ORM\Column(type: 'date')]
    private \DateTimeInterface $dayDate;

    #[ORM\ManyToOne(targetEntity: User::class, inversedBy: 'debates')]
    #[ORM\JoinColumn(nullable: false)]
    private User $createdBy;

    #[ORM\Column(type: 'string', length: 20, options: ['default' => 'ai'])]
    private string $authorType = 'ai';

    #[ORM\ManyToOne(targetEntity: WorkerRun::class, cascade: ['persist'])]
    #[ORM\JoinColumn(nullable: true)]
    private ?WorkerRun $workerRun = null;

    #[ORM\Column(type: 'string', length: 180, nullable: true)]
    private ?string $generationModel = null;

    #[ORM\Column(type: 'datetime')]
    private \DateTimeInterface $createdAt;

    #[ORM\OneToMany(targetEntity: Comment::class, mappedBy: 'debate')]
    private Collection $comments;

    public function __construct()
    {
        $this->createdAt = new \DateTime();
        $this->comments = new ArrayCollection();
    }

    public function getId(): ?int
    {
        return $this->id !== null ? (int) $this->id : null;
    }

    public function getTitle(): string
    {
        return $this->title;
    }

    public function setTitle(string $title): static
    {
        $this->title = $title;
        return $this;
    }

    public function getQuestion(): ?string
    {
        return $this->question;
    }

    public function setQuestion(?string $question): static
    {
        $this->question = $question;
        return $this;
    }

    public function getCardSummary(): ?string
    {
        return $this->cardSummary;
    }

    public function setCardSummary(?string $cardSummary): static
    {
        $this->cardSummary = $cardSummary;
        return $this;
    }

    public function getContext(): string
    {
        return $this->context;
    }

    public function setContext(string $context): static
    {
        $this->context = $context;
        return $this;
    }

    public function getSourceName(): ?string
    {
        return $this->sourceName;
    }

    public function setSourceName(?string $sourceName): static
    {
        $this->sourceName = $sourceName;
        return $this;
    }

    public function getSourceUrl(): ?string
    {
        return $this->sourceUrl;
    }

    public function setSourceUrl(?string $sourceUrl): static
    {
        $this->sourceUrl = $sourceUrl;
        return $this;
    }

    public function getPublishedAt(): ?\DateTimeInterface
    {
        return $this->publishedAt;
    }

    public function setPublishedAt(?\DateTimeInterface $publishedAt): static
    {
        $this->publishedAt = $publishedAt;
        return $this;
    }

    public function getDayDate(): \DateTimeInterface
    {
        return $this->dayDate;
    }

    public function setDayDate(\DateTimeInterface $dayDate): static
    {
        $this->dayDate = $dayDate;
        return $this;
    }

    public function getCreatedBy(): User
    {
        return $this->createdBy;
    }

    public function setCreatedBy(User $createdBy): static
    {
        $this->createdBy = $createdBy;
        return $this;
    }

    public function getAuthorType(): string
    {
        return $this->authorType;
    }

    public function setAuthorType(string $authorType): static
    {
        $this->authorType = $authorType;
        return $this;
    }

    public function getWorkerRun(): ?WorkerRun
    {
        return $this->workerRun;
    }

    public function setWorkerRun(?WorkerRun $workerRun): static
    {
        $this->workerRun = $workerRun;
        return $this;
    }

    public function getGenerationModel(): ?string
    {
        return $this->generationModel;
    }

    public function setGenerationModel(?string $generationModel): static
    {
        $this->generationModel = $generationModel;
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

    public function getComments(): Collection
    {
        return $this->comments;
    }
}
