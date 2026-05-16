<?php

declare(strict_types=1);

namespace App\Controller\Api;

use App\Entity\Debate;
use App\Entity\User;
use App\Repository\CommentRepository;
use App\Repository\DebateRepository;
use App\Service\DebateService;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\Routing\Attribute\Route;

#[Route('/api/v1/debates')]
class DebateController extends AbstractController
{
    public function __construct(
        private readonly DebateService $debateService,
        private readonly CommentRepository $commentRepository,
        private readonly DebateRepository $debateRepository,
    ) {
    }

    /** Debates para el ticker: top 20 por participación, con commentCount. */
    #[Route('/ticker', name: 'api_debates_ticker', methods: ['GET'])]
    public function ticker(): JsonResponse
    {
        $debates = $this->debateRepository->findForTicker(20);
        return new JsonResponse($this->normalizeDebates($debates));
    }

    /** Top debates de HOY por participación. */
    #[Route('/top-today', name: 'api_debates_top_today', methods: ['GET'])]
    public function topToday(): JsonResponse
    {
        $debates = $this->debateRepository->findTopToday(10);
        return new JsonResponse($this->normalizeDebates($debates));
    }

    /** Top debates de la SEMANA (últimos 7 días) por participación. */
    #[Route('/top-week', name: 'api_debates_top_week', methods: ['GET'])]
    public function topWeek(): JsonResponse
    {
        $debates = $this->debateRepository->findTopWeek(10);
        return new JsonResponse($this->normalizeDebates($debates));
    }

    /** Debates recientes con filtro opcional ?persona=username y paginación ?page=N. */
    #[Route('/recent', name: 'api_debates_recent', methods: ['GET'])]
    public function recent(Request $request): JsonResponse
    {
        $page    = max(1, (int) $request->query->get('page', '1'));
        $persona = $request->query->get('persona');
        $limit   = 20;
        $offset  = ($page - 1) * $limit;

        $debates = $this->debateRepository->findRecent($limit, $offset, $persona ?: null);
        return new JsonResponse($this->normalizeDebates($debates));
    }

    #[Route('/today', name: 'api_debates_today', methods: ['GET'])]
    public function today(): JsonResponse
    {
        $debates = $this->debateService->getTodaysDebates();
        return new JsonResponse($this->normalizeDebates($debates));
    }

    #[Route('/trending', name: 'api_debates_trending', methods: ['GET'])]
    public function trending(): JsonResponse
    {
        $debates = $this->debateService->getTrending();
        return new JsonResponse($this->normalizeDebates($debates));
    }

    #[Route('/search', name: 'api_debates_search', methods: ['GET'])]
    public function search(Request $request): JsonResponse
    {
        $query = $request->query->get('q', '');
        $page = max(1, (int) $request->query->get('page', '1'));

        if (empty($query)) {
            throw new \InvalidArgumentException('query parameter q is required');
        }

        $debates = $this->debateService->search($query, $page);
        return new JsonResponse($this->normalizeDebates($debates));
    }

    #[Route('/{id}', name: 'api_debates_show', methods: ['GET'], requirements: ['id' => '\d+'])]
    public function show(int $id): JsonResponse
    {
        $debate = $this->debateService->getDebate($id);
        return new JsonResponse($this->normalizeDebate($debate));
    }

    #[Route('', name: 'api_debates_propose', methods: ['POST'])]
    public function propose(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->attributes->get('currentUser');
        $data = json_decode($request->getContent(), true) ?? [];

        $debate = $this->debateService->proposeDebate($user, $data);

        return new JsonResponse($this->normalizeDebate($debate), 201);
    }

    private function normalizeDebate(Debate $debate): array
    {
        return [
            'id'              => $debate->getId(),
            'title'           => $debate->getTitle(),
            'question'        => $debate->getQuestion(),
            'cardSummary'     => $debate->getCardSummary(),
            'context'         => $debate->getContext(),
            'sourceName'      => $debate->getSourceName(),
            'sourceUrl'       => $debate->getSourceUrl(),
            'publishedAt'     => $debate->getPublishedAt()?->format(\DateTimeInterface::ATOM),
            'dayDate'         => $debate->getDayDate()->format('Y-m-d'),
            'authorType'      => $debate->getAuthorType(),
            'generationModel' => $debate->getGenerationModel(),
            'createdAt'       => $debate->getCreatedAt()->format(\DateTimeInterface::ATOM),
            'commentCount'    => $this->commentRepository->countByDebate($debate->getId()),
            'createdBy'       => [
                'id'               => $debate->getCreatedBy()->getId(),
                'username'         => $debate->getCreatedBy()->getUsername(),
                'avatarUrl'        => $debate->getCreatedBy()->getAvatarUrl(),
                'isAiPersona'      => $debate->getCreatedBy()->isAiPersona(),
                'personaSpecialty' => $debate->getCreatedBy()->getPersonaSpecialty(),
            ],
        ];
    }

    private function normalizeDebates(array $debates): array
    {
        return array_map(fn(Debate $d) => $this->normalizeDebate($d), $debates);
    }
}
