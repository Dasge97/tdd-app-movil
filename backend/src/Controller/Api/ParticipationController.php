<?php

declare(strict_types=1);

namespace App\Controller\Api;

use App\Entity\Comment;
use App\Entity\Position;
use App\Entity\User;
use App\Service\CommentService;
use App\Service\PositionService;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\Routing\Attribute\Route;

#[Route('/api/v1')]
class ParticipationController extends AbstractController
{
    public function __construct(
        private readonly PositionService $positionService,
        private readonly CommentService $commentService
    ) {
    }

    #[Route('/debates/{id}/positions', name: 'api_positions_set', methods: ['POST'], requirements: ['id' => '\d+'])]
    public function setPosition(int $id, Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->attributes->get('currentUser');
        $data = json_decode($request->getContent(), true) ?? [];
        $position = $data['position'] ?? '';

        $pos = $this->positionService->setPosition($user, $id, $position);

        return new JsonResponse($this->normalizePosition($pos), 201);
    }

    #[Route('/debates/{id}/positions', name: 'api_positions_get', methods: ['GET'], requirements: ['id' => '\d+'])]
    public function getPositions(int $id): JsonResponse
    {
        $counts = $this->positionService->getPositions($id);
        return new JsonResponse($counts);
    }

    #[Route('/debates/{id}/comments', name: 'api_comments_add', methods: ['POST'], requirements: ['id' => '\d+'])]
    public function addComment(int $id, Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->attributes->get('currentUser');
        $data = json_decode($request->getContent(), true) ?? [];
        $parentId = isset($data['parentId']) ? (int) $data['parentId'] : null;
        $content = $data['content'] ?? '';

        $comment = $this->commentService->addComment($user, $id, $parentId, $content);

        return new JsonResponse($this->normalizeComment($comment), 201);
    }

    #[Route('/debates/{id}/comments', name: 'api_comments_list', methods: ['GET'], requirements: ['id' => '\d+'])]
    public function getComments(int $id, Request $request): JsonResponse
    {
        /** @var User|null $user */
        $user = $request->attributes->get('currentUser');
        $parentId = $request->query->has('parentId') ? (int) $request->query->get('parentId') : null;

        if ($user === null) {
            throw new \RuntimeException('UNAUTHORIZED: authentication required');
        }

        $comments = $this->commentService->getComments($id, $parentId, $user);

        return new JsonResponse(array_map(fn(Comment $c) => $this->normalizeComment($c), $comments));
    }

    #[Route('/comments/{id}/vote', name: 'api_comments_vote', methods: ['POST'], requirements: ['id' => '\d+'])]
    public function voteComment(int $id, Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->attributes->get('currentUser');
        $data = json_decode($request->getContent(), true) ?? [];
        $value = isset($data['value']) ? (int) $data['value'] : 0;

        $this->commentService->voteComment($user, $id, $value);

        return new JsonResponse(['success' => true]);
    }

    private function normalizeComment(Comment $comment): array
    {
        return [
            'id'        => $comment->getId(),
            'content'   => $comment->getContent(),
            'score'     => $comment->getScore(),
            'createdAt' => $comment->getCreatedAt()->format(\DateTimeInterface::ATOM),
            'parentId'  => $comment->getParent()?->getId(),
            'debateId'  => $comment->getDebate()->getId(),
            'user'      => [
                'id'          => $comment->getUser()->getId(),
                'username'    => $comment->getUser()->getUsername(),
                'avatarUrl'   => $comment->getUser()->getAvatarUrl(),
                'isAiPersona' => $comment->getUser()->isAiPersona(),
            ],
        ];
    }

    private function normalizePosition(Position $position): array
    {
        return [
            'id'        => $position->getId(),
            'position'  => $position->getPosition(),
            'createdAt' => $position->getCreatedAt()->format(\DateTimeInterface::ATOM),
            'updatedAt' => $position->getUpdatedAt()?->format(\DateTimeInterface::ATOM),
            'userId'    => $position->getUser()->getId(),
            'debateId'  => $position->getDebate()->getId(),
        ];
    }
}
