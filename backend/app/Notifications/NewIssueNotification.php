<?php

namespace App\Notifications;

use App\Models\Issue;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;

class NewIssueNotification extends Notification
{
    use Queueable;

    public function __construct(public Issue $issue)
    {
    }

    public function via(object $notifiable): array
    {
        return ['database'];
    }

    public function toArray(object $notifiable): array
    {
        $checkpointName = 'Unknown Location';
        
        if ($this->issue->report->schedule) {
            $checkpointName = $this->issue->report->schedule->checkpoint->name;
        } else {
            // For OSB/Resepsionis reports without schedule
            $checkpointName = 'Lokasi Manual';
        }

        return [
            'issue_id' => $this->issue->id,
            'message' => 'Kendala baru dilaporkan: ' . $checkpointName,
            'issue_description' => $this->issue->issue_description,
            'report_id' => $this->issue->report_id,
        ];
    }
}
